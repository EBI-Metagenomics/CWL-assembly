import re

project_id_reg_no_anchors = re.compile("([E|S|D]RP\d{6,})")
run_id_reg_no_anchors = re.compile("([E|S|D]R[R|S]\d{6,})")

study_id_reg = re.compile("^([E|S|D]RP\d{6,})$")
run_id_reg = re.compile("^([E|S|D]R[R|S]\d{6,})$")

study_container_reg = re.compile("^([E|S|D]RP\d{4})$")
run_container_reg = re.compile("^([E|S|D]R[R|S]\d{4})$")
