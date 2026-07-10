#!/usr/bin/env python3

import re
import sys

blast_file = sys.argv[1]
top_n = 5

results = {}


with open(blast_file) as f:
    for line in f:

        line = line.rstrip()

        if not line:
            continue

        # First two fields are query and qlen
        first = line.split(maxsplit=2)

        if len(first) < 3:
            continue

        query = first[0]
        qlen = first[1]

        rest = first[2]

        # Extract numeric BLAST fields from the end
        # pident length qcovs qstart qend sstart send evalue bitscore
        nums = rest.rsplit(maxsplit=9)

        if len(nums) != 10:
            continue

        stitle = nums[0]

        ident = nums[1]
        aln_len = nums[2]
        qcovs = nums[3]


        if query not in results:
            results[query] = {
                "length": qlen,
                "hits": []
            }


        if len(results[query]["hits"]) >= top_n:
            continue


        # ----------------------------
        # Parse target ID
        # ----------------------------
        target = stitle.split()[0]


        # ----------------------------
        # Parse taxonomy
        # ----------------------------
        tax_match = re.search(
            r'(d__.*?)(?=\s*\[|$)',
            stitle
        )

        last_two = ""

        if tax_match:

            taxa = [
                x.strip()
                for x in tax_match.group(1).split(";")
                if x.strip() and not x.endswith("__")
            ]

            if len(taxa) >= 2:
                last_two = ",".join(taxa[-2:])

            elif len(taxa) == 1:
                last_two = taxa[0]


        # Match format:
        # target,last_two_taxa,alignment_length,qcovs,identity

        match = ",".join(
            [
                target,
                last_two,
                aln_len,
                qcovs,
                ident
            ]
        )


        results[query]["hits"].append(match)



# ----------------------------
# Output
# ----------------------------

print("# 16S BLAST hits: Match = target ID,last two taxonomy levels,alignment length(bp),query coverage(%),identity(%)")


header = ["Sample", "Length"]

for i in range(1, top_n + 1):
    header.append(f"Match{i}")

print("\t".join(header))


for query in sorted(results):

    row = [
        query,
        results[query]["length"]
    ]

    row.extend(results[query]["hits"])


    while len(row) < len(header):
        row.append("")


    print("\t".join(row))
