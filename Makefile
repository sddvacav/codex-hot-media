.PHONY: install-local test smoke build clean

install-local:
	python -m pip install -e .

test:
	python -m unittest discover -s tests -p "test_*.py"

smoke:
	codex-hot-media --json doctor
	codex-hot-media --json sources
	codex-hot-media --json agent-guide
	codex-hot-media --json import-text --input examples/manual_hot_titles.txt --source-name manual --out-dir tmp_smoke/data --prefix manual_hot
	codex-hot-media --json plan --input tmp_smoke/data/manual_hot_latest.json --top-n 3 --out-dir tmp_smoke
	codex-hot-media --json pack --plan tmp_smoke/video_plan_from_hot_latest.json --out-dir tmp_smoke
	codex-hot-media --json dashboard --plan tmp_smoke/video_plan_from_hot_latest.json --pack tmp_smoke/publish_pack/publish_pack_latest.json --out tmp_smoke/dashboard.html

build:
	python -m pip install build
	python -m build

clean:
	rm -rf build dist *.egg-info tmp_smoke .pytest_cache
