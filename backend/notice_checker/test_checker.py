import copy
import io
import json
import unittest
from datetime import timedelta
from urllib.error import HTTPError
from unittest.mock import MagicMock, Mock, patch

from checker import (CheckerError, FirebaseSender, GitHubStateStore, TEST_TOPIC,
                     PRODUCTION_TOPIC, RECENT_NOTICE_LIMIT, baseline, batch_message,
                     check, fetch_notices, initial_state, now, parse_notices, validate_state)

SOURCE = "https://igitsarang.ac.in/notice/2026"


def notice(i, title=None):
    return {"id": str(i), "title": title or f"Notice {i}", "date": "8 October 2026",
            "url": f"https://igitsarang.ac.in/assets/{i}.pdf"}


class MemoryStore:
    def __init__(self, state=None):
        self.state = copy.deepcopy(state or initial_state())
        self.writes = []

    def load(self):
        return copy.deepcopy(self.state)

    def save(self, state):
        self.state = copy.deepcopy(state)
        self.writes.append(copy.deepcopy(state))


class NoticeCheckerTests(unittest.TestCase):
    def test_single_notice_uses_four_word_preview_without_more_count(self):
        message = batch_message([notice(1, "Odd semester back paper registration for students")], audience="production")
        self.assertEqual(message["title"], "New college notice")
        self.assertEqual(message["body"], "Odd semester back paper… · Tap to view notice")

    def test_multiple_notices_preview_only_first_title_and_remaining_count(self):
        for count in (2, 3, 10):
            with self.subTest(count=count):
                notices = [notice(1, "Odd semester back paper registration")]
                notices += [notice(i, "Other notice title") for i in range(2, count + 1)]
                message = batch_message(notices, audience="production")
                self.assertEqual(message["title"], f"{count} new college notices")
                self.assertEqual(message["body"], f"Odd semester back paper… · +{count - 1} more · Tap to view all")
                self.assertEqual(message["data"]["notice_count"], str(count))

    def test_short_title_is_not_ellipsized_and_long_word_is_bounded(self):
        message = batch_message([notice(1, "  Exam\n timetable  ")])
        self.assertEqual(message["body"], "Exam timetable · Tap to view notice")
        message = batch_message([notice(1, "ଅ" * 1000)])
        self.assertEqual(message["body"], "ଅ" * 96 + "… · Tap to view notice")
        self.assertLess(len(message["body"].encode()), 850)

    def test_parser_links_entities_and_stable_site_id(self):
        rows = '''<table>
          <tr id="noticerow_991"><td><a href="/one.pdf">Exam &amp; registration</a></td><td>8 October</td><td></td></tr>
          <tr id="noticerow_992"><td><a href="#">Second<br>notice</a></td><td>7 October</td><td><a href="/two.pdf">Download</a></td></tr>
        </table>'''
        parsed = parse_notices(rows, SOURCE)
        self.assertEqual(parsed[0]["title"], "Exam & registration")
        self.assertEqual(parsed[1]["title"], "Second notice")
        self.assertEqual(parsed[1]["url"], "https://igitsarang.ac.in/two.pdf")
        edited = parse_notices(rows.replace("Exam &amp; registration", "Edited title"), SOURCE)
        self.assertEqual(parsed[0]["id"], edited[0]["id"])
        self.assertNotEqual(parsed[0]["id"], parse_notices(rows, SOURCE.replace("2026", "2027"))[0]["id"])

    def test_reject_empty_partial_login_and_duplicate_pages(self):
        for html in ("<html>Login</html>", "<table></table>",
                     '<tr id="noticerow_1"><td>Partial</td></tr>',
                     '<tr id="noticerow_1"><td>Title</td><td>Date</td><td><a href="javascript:alert(1)">Open</a></td></tr>'):
            with self.subTest(html=html), self.assertRaises(ValueError):
                parse_notices(html, SOURCE)
        row = '<tr id="noticerow_1"><td>Title</td><td>Date</td><td><a href="/a.pdf">Open</a></td></tr>'
        with self.assertRaises(ValueError):
            parse_notices(row * 2, SOURCE)

    def test_text_only_notices_use_the_notice_list_as_fallback(self):
        rows = '''<table>
          <tr id="noticerow_1"><td>Text-only announcement</td><td>8 October</td><td></td></tr>
          <tr id="noticerow_2"><td><a href="#">Another announcement</a></td><td>8 October</td><td><a href=" ">Download</a></td></tr>
        </table>'''
        notices = parse_notices(rows, SOURCE)
        self.assertEqual(len(notices), 2)
        self.assertEqual([n["url"] for n in notices], [SOURCE, SOURCE])

    def test_text_only_new_notice_does_not_block_other_notices(self):
        old = '<tr id="noticerow_1"><td>Previous</td><td>7 October</td><td><a href="/old.pdf">PDF</a></td></tr>'
        added = '<tr id="noticerow_2"><td>Text only</td><td>8 October</td><td></td></tr>'
        store, sender = MemoryStore(), Mock()
        check(store, lambda _: parse_notices(old, SOURCE), sender, year=2026)
        check(store, lambda _: parse_notices(added + old, SOURCE), sender, year=2026)
        sender.assert_called_once_with(parse_notices(added, SOURCE))

    def test_first_run_silently_baselines_all_notices(self):
        store, sender = MemoryStore(), Mock()
        check(store, lambda _: [notice(1), notice(2)], sender, year=2026)
        sender.assert_not_called()
        self.assertEqual(store.state["years"]["2026"], ["1", "2"])
        self.assertEqual(len(store.writes), 1)

    def baselined_store(self):
        state = initial_state()
        state["years"] = {"2026": ["1"]}
        return MemoryStore(state)

    def test_multiple_new_notices_use_one_durable_batch(self):
        store = self.baselined_store()
        def send(batch):
            self.assertEqual(store.state["pending"]["notices"], batch)
            self.assertEqual(store.state["years"]["2026"], ["1"])
        sender = Mock(side_effect=send)
        check(store, lambda _: [notice(3), notice(2), notice(1)], sender, year=2026)
        sender.assert_called_once_with([notice(3), notice(2)])
        self.assertEqual(store.state["years"]["2026"], ["3", "2", "1"])
        self.assertIsNone(store.state["pending"])
        self.assertEqual(len(store.writes), 2)

    def test_unchanged_or_reordered_list_never_sends_or_commits(self):
        store, sender = self.baselined_store(), Mock()
        check(store, lambda _: [notice(1, "Edited existing notice")], sender, year=2026)
        sender.assert_not_called()
        self.assertEqual(store.writes, [])

    def test_failed_send_is_retried_from_persistent_pending_batch(self):
        store = self.baselined_store()
        with self.assertRaises(RuntimeError):
            check(store, lambda _: [notice(2), notice(1)], Mock(side_effect=RuntimeError), year=2026)
        self.assertEqual(store.state["years"]["2026"], ["1"])
        self.assertEqual(store.state["pending"]["notices"], [notice(2)])
        sender = Mock()
        check(store, lambda _: [notice(3), notice(2), notice(1)], sender, year=2026)
        self.assertEqual([c.args[0] for c in sender.call_args_list], [[notice(2)], [notice(3)]])
        self.assertEqual(store.state["years"]["2026"], ["3", "2", "1"])

    def test_pending_batch_is_delivered_before_a_failed_website_fetch(self):
        store = self.baselined_store()
        store.state["pending"] = {"year": "2026", "notices": [notice(2)], "retained_ids": ["2", "1"]}
        order = []
        sender = Mock(side_effect=lambda _: order.append("send"))
        def fetch(_):
            order.append("fetch")
            raise RuntimeError("College website unavailable")
        with self.assertRaises(RuntimeError):
            check(store, fetch, sender, year=2026)
        self.assertEqual(order, ["send", "fetch"])
        self.assertIsNone(store.state["pending"])
        self.assertEqual(store.state["years"]["2026"], ["2", "1"])

    def test_december_batch_is_delivered_when_new_year_page_is_missing(self):
        store = self.baselined_store()
        store.state["pending"] = {"year": "2026", "notices": [notice(2)], "retained_ids": ["2", "1"]}
        sender = Mock()
        error = HTTPError("url", 404, "new year page not published", {}, io.BytesIO())
        self.addCleanup(error.close)
        with self.assertRaises(HTTPError):
            check(store, Mock(side_effect=error), sender, year=2027)
        sender.assert_called_once_with([notice(2)])
        self.assertIsNone(store.state["pending"])
        self.assertEqual(store.state["years"], {"2026": ["2", "1"]})

    def test_pending_send_failure_preserves_snapshot_without_fetching_page(self):
        store = self.baselined_store()
        store.state["pending"] = {"year": "2026", "notices": [notice(2)], "retained_ids": ["2", "1"]}
        fetch = Mock()
        with self.assertRaises(RuntimeError):
            check(store, fetch, Mock(side_effect=RuntimeError), year=2026)
        fetch.assert_not_called()
        self.assertEqual(store.state["pending"]["retained_ids"], ["2", "1"])
        self.assertNotIn("claim_until", store.state["pending"])

    def test_retry_during_outage_preserves_late_insertion_window_order(self):
        store, sender = MemoryStore(), Mock()
        rows = [notice(i) for i in range(100, 0, -1)]
        check(store, lambda _: rows, sender, year=2026)
        rows.insert(99, notice(101))
        with self.assertRaises(RuntimeError):
            check(store, lambda _: rows, Mock(side_effect=RuntimeError), year=2026)
        with self.assertRaises(RuntimeError):
            check(store, Mock(side_effect=RuntimeError), sender, year=2026)
        sender.assert_called_once_with([notice(101)])
        self.assertEqual(store.state["years"]["2026"], [n["id"] for n in rows[:100]])
        check(store, lambda _: rows, sender, year=2026)
        self.assertEqual(sender.call_count, 1)

    def test_corrupt_pending_snapshot_cannot_be_acknowledged_or_sent(self):
        store, sender = self.baselined_store(), Mock()
        store.state["pending"] = {"year": "2026", "notices": [notice(2)], "retained_ids": ["unknown-id"]}
        with self.assertRaises(ValueError):
            check(store, Mock(), sender, year=2026)
        sender.assert_not_called()
        self.assertEqual(store.writes, [])

    def test_state_write_failure_prevents_send(self):
        store, sender = self.baselined_store(), Mock()
        store.save = Mock(side_effect=RuntimeError)
        with self.assertRaises(RuntimeError):
            check(store, lambda _: [notice(2), notice(1)], sender, year=2026)
        sender.assert_not_called()

    def test_source_failure_or_empty_list_keeps_history(self):
        for fetch in (Mock(side_effect=RuntimeError), lambda _: []):
            store, sender = self.baselined_store(), Mock()
            with self.assertRaises((RuntimeError, ValueError)):
                check(store, fetch, sender, year=2026)
            self.assertEqual(store.writes, [])
            sender.assert_not_called()

    def test_new_year_sends_first_new_notices(self):
        store, sender = self.baselined_store(), Mock()
        check(store, lambda _: [notice(8)], sender, year=2027)
        sender.assert_called_once_with([notice(8)])
        self.assertEqual(store.state["years"], {"2026": ["1"], "2027": ["8"]})

    def test_history_stays_bounded_over_many_updates(self):
        store, sender = MemoryStore(), Mock()
        check(store, lambda _: [notice(i) for i in range(250, 0, -1)], sender, year=2026)
        self.assertEqual(len(store.state["years"]["2026"]), RECENT_NOTICE_LIMIT)
        for latest in range(251, 275):
            check(store, lambda _: [notice(i) for i in range(latest, 0, -1)], sender, year=2026)
            self.assertEqual(len(store.state["years"]["2026"]), RECENT_NOTICE_LIMIT)
        self.assertEqual(sender.call_count, 24)
        self.assertEqual(store.state["years"]["2026"][0], "274")

    def test_removed_anchors_and_older_rows_do_not_create_false_alerts(self):
        store, sender = MemoryStore(), Mock()
        check(store, lambda _: [notice(i) for i in range(250, 0, -1)], sender, year=2026)
        # Remove the top five and bottom five saved anchors from the website.
        remaining = [notice(i) for i in range(245, 0, -1) if i not in range(151, 156)]
        check(store, lambda _: remaining, sender, year=2026)
        sender.assert_not_called()
        check(store, lambda _: [notice(251)] + remaining, sender, year=2026)
        sender.assert_called_once_with([notice(251)])

    def test_inserted_notice_between_saved_anchors_is_detected(self):
        state = initial_state()
        state["years"] = {"2026": ["5", "4", "3", "2", "1"]}
        store, sender = MemoryStore(state), Mock()
        check(store, lambda _: [notice(i) for i in [5, 4, 6, 3, 2, 1]], sender, year=2026)
        sender.assert_called_once_with([notice(6)])

    def test_late_insertions_near_window_end_do_not_realert_pruned_old_ids(self):
        store, sender = MemoryStore(), Mock()
        rows = [notice(i) for i in range(100, 0, -1)]
        check(store, lambda _: rows, sender, year=2026)
        rows.insert(99, notice(101))
        check(store, lambda _: rows, sender, year=2026)
        rows.insert(99, notice(102))
        check(store, lambda _: rows, sender, year=2026)
        self.assertEqual([c.args[0] for c in sender.call_args_list], [[notice(101)], [notice(102)]])
        check(store, lambda _: rows, sender, year=2026)
        self.assertEqual(sender.call_count, 2)
        self.assertEqual(len(store.state["years"]["2026"]), RECENT_NOTICE_LIMIT)

    def test_racing_worker_cannot_send_an_already_claimed_pending_batch(self):
        store = self.baselined_store()
        second_sender = Mock()
        rows = [notice(2), notice(1)]
        def send(_):
            check(store, lambda _: rows, second_sender, year=2026)
        first_sender = Mock(side_effect=send)
        check(store, lambda _: rows, first_sender, year=2026)
        first_sender.assert_called_once()
        second_sender.assert_not_called()
        self.assertIsNone(store.state["pending"])

    def test_abandoned_delivery_claim_retries_after_expiry(self):
        store = self.baselined_store()
        store.state["pending"] = {
            "year": "2026", "notices": [notice(2)],
            "claim_until": (now() - timedelta(seconds=1)).isoformat(),
        }
        sender = Mock()
        check(store, lambda _: [notice(2), notice(1)], sender, year=2026)
        sender.assert_called_once_with([notice(2)])
        self.assertIsNone(store.state["pending"])

    def test_corrupt_delivery_claim_stops_without_sending(self):
        store, sender = self.baselined_store(), Mock()
        store.state["pending"] = {"year": "2026", "notices": [notice(2)], "claim_until": "invalid"}
        with self.assertRaises(CheckerError):
            check(store, lambda _: [notice(2), notice(1)], sender, year=2026)
        sender.assert_not_called()

    def test_complete_anchor_loss_stops_without_sending_or_resetting(self):
        store, sender = self.baselined_store(), Mock()
        with self.assertRaises(CheckerError):
            check(store, lambda _: [notice(5), notice(4)], sender, year=2026)
        sender.assert_not_called()
        self.assertEqual(store.writes, [])

    def test_history_older_than_previous_year_is_removed(self):
        store, sender = self.baselined_store(), Mock()
        store.state["years"].update({"2023": ["old"], "2024": ["older"], "2025": ["previous"]})
        check(store, lambda _: [notice(1)], sender, year=2026)
        self.assertEqual(set(store.state["years"]), {"2025", "2026"})
        sender.assert_not_called()

    @patch.dict("os.environ", {"NOTICE_PRODUCTION_ENABLED": "false"})
    def test_production_check_is_blocked_before_reading_or_sending(self):
        store, fetch, sender = Mock(), Mock(), Mock()
        with self.assertRaises(CheckerError):
            check(store, fetch, sender, year=2026, audience="production")
        store.load.assert_not_called()
        fetch.assert_not_called()
        sender.assert_not_called()

    @patch.dict("os.environ", {"NOTICE_PRODUCTION_ENABLED": "false"})
    def test_sender_independently_blocks_production_delivery(self):
        sender = FirebaseSender.__new__(FirebaseSender)
        sender.messaging, sender.app, sender.audience = Mock(), object(), "production"
        with self.assertRaises(CheckerError):
            sender.send([notice(1)])
        sender.messaging.send.assert_not_called()

    @patch.dict("os.environ", {"NOTICE_PRODUCTION_ENABLED": "false"})
    def test_production_validation_never_delivers_and_uses_correct_topic(self):
        sender = FirebaseSender.__new__(FirebaseSender)
        sender.messaging, sender.app, sender.audience = Mock(), object(), "production"
        sender.send([notice(1)], dry_run=True)
        self.assertEqual(sender.messaging.Message.call_args.kwargs["topic"], PRODUCTION_TOPIC)
        self.assertEqual(sender.messaging.Message.call_args.kwargs["data"]["test"], "false")
        self.assertTrue(sender.messaging.send.call_args.kwargs["dry_run"])

    @patch.dict("os.environ", {"NOTICE_PRODUCTION_ENABLED": "true"})
    def test_enabled_production_check_uses_isolated_history(self):
        state = initial_state("production")
        state["years"] = {"2026": ["1"]}
        store, sender = MemoryStore(state), Mock()
        check(store, lambda _: [notice(2), notice(1)], sender, year=2026, audience="production")
        sender.assert_called_once_with([notice(2)])
        self.assertEqual(store.state["topic"], PRODUCTION_TOPIC)
        with self.assertRaises(ValueError):
            validate_state(store.state, "test")

    def test_production_baseline_is_silent_and_bounded_with_gate_disabled(self):
        store = MemoryStore(initial_state("production"))
        baseline(store, lambda _: [notice(i) for i in range(200, 0, -1)], year=2026, audience="production")
        self.assertEqual(store.state["topic"], PRODUCTION_TOPIC)
        self.assertEqual(len(store.state["years"]["2026"]), RECENT_NOTICE_LIMIT)
        self.assertIsNone(store.state["pending"])

    def test_manual_baseline_cannot_discard_pending_delivery(self):
        store = self.baselined_store()
        store.state["pending"] = {"year": "2026", "notices": [notice(2)]}
        with self.assertRaises(CheckerError):
            baseline(store, lambda _: [notice(2), notice(1)], year=2026)
        self.assertEqual(store.writes, [])

    @patch("checker.time.sleep")
    @patch("checker.urlopen")
    def test_notice_fetch_retries_transient_failure(self, open_url, sleep):
        response = MagicMock()
        response.__enter__.return_value = response
        response.url = SOURCE
        response.read.return_value = b'<tr id="noticerow_1"><td>Title</td><td>Date</td><td><a href="/a.pdf">PDF</a></td></tr>'
        open_url.side_effect = [HTTPError(SOURCE, 503, "unavailable", {}, io.BytesIO()), response]
        self.assertEqual(len(fetch_notices(2026)), 1)
        self.assertEqual(open_url.call_count, 2)
        sleep.assert_called_once_with(1)

    @patch("checker.time.sleep")
    @patch("checker.urlopen")
    def test_notice_fetch_does_not_retry_access_denied(self, open_url, sleep):
        open_url.side_effect = HTTPError(SOURCE, 403, "forbidden", {}, io.BytesIO())
        with self.assertRaises(HTTPError):
            fetch_notices(2026)
        self.assertEqual(open_url.call_count, 1)
        sleep.assert_not_called()

    @patch.dict("os.environ", {"GITHUB_REPOSITORY": "owner/repo", "GH_TOKEN": "fake"})
    def test_production_requires_explicit_first_baseline(self):
        store = GitHubStateStore("production")
        store.api = Mock(side_effect=HTTPError("url", 404, "missing", {}, io.BytesIO()))
        with self.assertRaises(CheckerError):
            store.load()

    @patch.dict("os.environ", {"GITHUB_REPOSITORY": "owner/repo", "GH_TOKEN": "fake"})
    def test_production_baseline_adds_separate_file_without_replacing_test_history(self):
        store = GitHubStateStore("production", allow_missing=True)
        store.api = Mock(side_effect=[{}, HTTPError("url", 404, "missing", {}, io.BytesIO())])
        state = store.load()
        self.assertEqual(state["topic"], PRODUCTION_TOPIC)
        store.api = Mock(return_value={"content": {"sha": "new-sha"}})
        store.save(state)
        self.assertEqual(store.api.call_args.args[0], "/contents/notices-production.json")
        self.assertNotIn("sha", store.api.call_args.kwargs["data"])

    def test_large_unicode_batch_stays_below_topic_payload_limit(self):
        notices = [notice(i, "📚" * 500) for i in range(100)]
        message = batch_message(notices, test=True)
        self.assertEqual(message["data"]["notice_count"], "100")
        self.assertEqual(message["data"]["route"], "/notice")
        self.assertLess(len(json.dumps(message, ensure_ascii=False).encode()), 2048)
        self.assertEqual(batch_message(list(reversed(notices)))["data"]["batch_id"], message["data"]["batch_id"])

    def test_firebase_sender_can_only_address_the_fixed_test_topic(self):
        sender = FirebaseSender.__new__(FirebaseSender)
        sender.messaging, sender.app = Mock(), object()
        sender.send([notice(1), notice(2)])
        kwargs = sender.messaging.Message.call_args.kwargs
        self.assertEqual(kwargs["topic"], TEST_TOPIC)
        self.assertNotIn("token", kwargs)
        self.assertNotIn("condition", kwargs)
        self.assertEqual(kwargs["data"]["notice_count"], "2")
        sender.messaging.send.assert_called_once()

    def test_failure_after_send_preserves_retryable_outbox(self):
        store, sender = self.baselined_store(), Mock()
        real_save = store.save
        def save(state):
            if state["pending"] is None:
                raise RuntimeError("GitHub unavailable after Firebase accepted send")
            real_save(state)
        store.save = save
        with self.assertRaises(RuntimeError):
            check(store, lambda _: [notice(2), notice(1)], sender, year=2026)
        sender.assert_called_once()
        self.assertEqual(store.state["pending"]["notices"], [notice(2)])
        self.assertEqual(store.state["years"]["2026"], ["1"])

    @patch.dict("os.environ", {"GITHUB_REPOSITORY": "owner/repo", "GH_TOKEN": "fake"})
    def test_missing_state_on_existing_branch_is_not_silently_reset(self):
        store = GitHubStateStore()
        error = HTTPError("url", 404, "missing", {}, io.BytesIO())
        self.addCleanup(error.close)
        store.api = Mock(side_effect=[{}, error])
        with self.assertRaises(HTTPError):
            store.load()

    @patch.dict("os.environ", {"GITHUB_REPOSITORY": "owner/repo", "GH_TOKEN": "fake"})
    def test_state_updates_use_blob_sha_and_fixed_test_branch(self):
        store = GitHubStateStore()
        store.branch_exists, store.sha = True, "old-sha"
        store.api = Mock(return_value={"content": {"sha": "new-sha"}})
        store.save(initial_state())
        body = store.api.call_args.kwargs["data"]
        self.assertEqual(body["sha"], "old-sha")
        self.assertEqual(body["branch"], "notification-state")
        self.assertEqual(store.sha, "new-sha")
        self.assertEqual(initial_state()["topic"], TEST_TOPIC)


if __name__ == "__main__":
    unittest.main()
