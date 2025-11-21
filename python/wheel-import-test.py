from module.dconcat_module import dconcat, ddiff_source, ddiff_change, data_set_print

def main() -> None:
    SRC_DATASET="audit.current.seq"
    CHANGE_DATASET="audit.previous.seq"
    MERGE_DATASET="audit.all.seq"
    REVERSE=False
    SEP_LINE="\n-------------------------------------------------------------------------------\n"

    # print(SEP_LINE + "[INFO] Running dconcat utility, review data set results in stdout." + SEP_LINE)
    dconcat(source=SRC_DATASET, change=CHANGE_DATASET,merge=MERGE_DATASET,reverse=REVERSE)

    print(SEP_LINE + "[INFO] Compare the current audit log to prior audit log entries." + SEP_LINE)
    print(ddiff_source(source=SRC_DATASET, change=CHANGE_DATASET))

    print(SEP_LINE + "[INFO] Compare prior audit log to the current audit log." + SEP_LINE)
    print(ddiff_change(source=SRC_DATASET, change=CHANGE_DATASET))

    print(SEP_LINE +"[INFO] Showing source dataset content." + SEP_LINE)
    print(data_set_print(source=SRC_DATASET))

    print(SEP_LINE +"[INFO] Showing change dataset content." + SEP_LINE)
    print(data_set_print(source=CHANGE_DATASET))

if __name__ == "__main__":
    main()