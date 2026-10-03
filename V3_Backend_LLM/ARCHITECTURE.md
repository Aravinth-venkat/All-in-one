# V3 — Backend + LLM Architecture

## AI Interview Coach flow
Question → User Answer → Structured LLM Evaluation → Score → Missing Concepts → Tips → Better Explanation → Follow-up

## Evaluation dimensions
- Technical accuracy
- Relevance
- Completeness
- Reasoning
- Communication structure
- Examples
- Scenario handling
- Resume/JD alignment

## Interview Rescue
If the user selects “I Don't Know”:
1. Hint
2. Concept clue
3. Keywords
4. Answer framework
5. Example answer
6. Retry
7. Learn the weak topic

## Adaptive questions
Follow-up questions should be generated from the user's previous answer and the current resume/JD context. Equivalent wording must receive credit when technically correct.

## Safety and quality
- Never expose model API keys in frontend code.
- Validate uploaded files.
- Limit file size/type.
- Treat resume/JD content as untrusted input.
- Use structured JSON schemas for LLM responses.
- Store only data the product actually needs.
- Allow users to delete stored resume/JD data.
