---
name: pdf-forms
description: Analyze, fill, and verify PDF forms programmatically. Use when user needs to fill out government forms, applications, or any fillable PDF.
triggers:
  - fill pdf
  - pdf form
  - fillable pdf
  - form filling
---

# PDF Forms Skill

Analyze and fill PDF forms programmatically, with visual verification.

## Capabilities

1. **Analyze** - Discover all fillable fields in a PDF with their positions
2. **Fill** - Programmatically fill form fields
3. **Preview** - Render filled PDF to image for visual verification

## Tools

### 1. Analyze PDF Form Fields

```bash
~/.config/pai/Skills/pdf-forms/tools/pdf-analyze <pdf-path>
```

Returns all form fields sorted by position (top to bottom), showing:
- Field name
- Field type (text, checkbox, signature)
- Y position (helps identify which row)

### 2. Fill PDF Form

```bash
~/.config/pai/Skills/pdf-forms/tools/pdf-fill <input-pdf> <output-pdf> '<json-field-data>'
```

Example:
```bash
~/.config/pai/Skills/pdf-forms/tools/pdf-fill \
  ~/Downloads/form.pdf \
  ~/Downloads/form-filled.pdf \
  '{"Text1-A": "John Doe", "SSN-A": "XXX-XX-1234"}'
```

### 3. Preview Filled PDF (Visual Verification)

```bash
~/.config/pai/Skills/pdf-forms/tools/pdf-preview <pdf-path> [page-number]
```

Renders PDF page to PNG image in /tmp for visual verification.
Returns the image path so Claude can view it.

### 4. Collect/Template Required Info

```bash
~/.config/pai/Skills/pdf-forms/tools/pdf-collect <pdf-path> [output.json]
```

Analyzes the form and generates a JSON template with all fields.
User can edit the template, then use pdf-fill.

Example:
```bash
# Generate template
pdf-collect ~/Downloads/form.pdf ~/Downloads/form-data.json

# Edit the JSON file with your data
# Then fill the form
pdf-fill ~/Downloads/form.pdf ~/Downloads/filled.pdf "$(cat ~/Downloads/form-data.json)"
```

## Workflow

1. **Download the form** - `curl -o ~/Downloads/form.pdf <url>`
2. **Analyze fields** - Run pdf-analyze to discover field names and positions
3. **Map your data** - Match your data to field names based on position
4. **Fill the form** - Run pdf-fill with JSON data
5. **Verify visually** - Run pdf-preview and view the image to confirm
6. **Iterate if needed** - Fix field mappings and re-fill

## Dependencies

- `poppler` (brew install poppler) - for pdftotext and pdftoppm
- `pypdf` (uv pip install pypdf) - for form filling

## Example Session

```
User: Fill out this tax form for me
Assistant:
1. Downloads form
2. Runs pdf-analyze to find fields
3. Maps user data to fields
4. Runs pdf-fill to create filled version
5. Runs pdf-preview to generate image
6. Shows image to user for verification
7. Iterates if fields are in wrong spots
```

## Field Position Tips

- Higher Y value = closer to TOP of page
- Fields on same row have similar Y values (within ~10 units)
- X value indicates horizontal position (left to right)
- Some forms use single field for "Last, First MI" instead of separate fields

## Collecting User Info

When filling a form, Claude should:

1. **Analyze the form first** to understand what info is needed
2. **Check for existing docs** - ask if user has related documents (IDs, bills, registrations) that contain the needed info
3. **Extract from docs** - Use pdftotext or image reading to pull data from source documents
4. **Ask for missing info** - Only prompt for info that can't be extracted
5. **Confirm before filling** - Show user what data will be used

### Common Info Sources

| Info Needed | Likely Source |
|-------------|---------------|
| Name, Address | Driver's license, utility bill, ID card |
| Vehicle info | Registration, insurance card, title |
| SSN | Tax documents (ask user to provide last 4) |
| Dates | Leases, registrations, receipts |

### Privacy Best Practices

- Ask for "last 4 of SSN" not full SSN when possible
- Don't store sensitive info after session
- Remind user to review before submitting
- Keep filled forms in ~/Downloads, not /tmp
