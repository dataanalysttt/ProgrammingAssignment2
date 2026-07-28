from app.processing.tagging import tag_item


def test_rbi_repo_rate_gets_expected_tags():
    tags = tag_item(
        "RBI hikes repo rate by 25 bps",
        "The Reserve Bank of India raised the repo rate citing inflation and crude oil prices.",
    )
    assert "india_economy_markets" in tags["category"]
    assert "rates" in tags["macro"]
    assert "crude" in tags["macro"]


def test_unrelated_headline_gets_no_macro_tags():
    tags = tag_item("Local school wins regional art competition", "Students celebrate their win.")
    assert tags["macro"] == []


def test_multiple_categories_can_match():
    tags = tag_item(
        "Parliament debates new GST reform bill amid inflation concerns",
        "Lok Sabha members discussed the fiscal deficit and GST changes.",
    )
    assert "india_politics_policy" in tags["category"]
    assert "india_economy_markets" in tags["category"]
