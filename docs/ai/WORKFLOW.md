# Multi-model quality workflow

Default roles:
1. Claude = Builder
2. ChatGPT/Codex = independent Reviewer
3. Gemini = mandatory Final Verifier

Builder gets locked task + root/local rules + current state + relevant plan slice + minimum source/tests.

Reviewer gets the same locked task plus latest diff and test/CI evidence, not the Builder's long reasoning as authority. Review concrete correctness, scope, auth/privacy, framework, DB/performance, and meaningful test defects.

Final Verifier runs only after Reviewer approval and independently checks the latest exact reviewed diff, unresolved findings, trust/architecture boundaries, and evidence.

Merge only after Builder ready, Reviewer approve, Final Verifier approve, exact-path validation, and CI green on the latest exact PR head. Unresolved reviewer/verifier disagreement requires human arbitration.
