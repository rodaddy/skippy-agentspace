# Medium Article Pattern

Medium requires search-then-click for full paywalled content. Direct URL navigation only shows the preview.

## Single Article

```bash
# 1. Extract slug from URL (path segment before the hash)
#    https://medium.com/pub/my-article-title-abc123def456
#    slug = "my-article-title"

# 2. Search for it
browse --session read-medium open "https://medium.com/search?q=<slug>"

# 3. Wait for results, click through
sleep 2
browse --session read-medium find text "<Article Title>" click

# 4. Wait for full render, extract
sleep 3
browse --session read-medium eval 'Array.from(document.querySelectorAll("p[data-selectable-paragraph], h1[data-selectable-paragraph], h2[data-selectable-paragraph], h3[data-selectable-paragraph], h4[data-selectable-paragraph], blockquote p")).map(el => el.innerText).join("\n\n")'

# 5. ALWAYS close
browse --session read-medium close
```

## Medium List

```bash
# 1. Open list page directly (lists load without search-click)
browse --session read-list open "https://medium.com/@user/list/list-name-hash"

# 2. Get all article titles
browse --session read-list eval 'JSON.stringify(Array.from(document.querySelectorAll("article h2")).map(h => h.innerText))'

# 3. Click an article from the list
browse --session read-list find text "<Title>" click
sleep 3

# 4. Extract full text (same eval as single article)
# 5. Go back for next article
browse --session read-list back
sleep 2

# 6. Close when done
browse --session read-list close
```
