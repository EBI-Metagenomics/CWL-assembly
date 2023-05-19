import re
from enum import Enum

project_id_reg_no_anchors = re.compile("([ESD]RP\d{6,})")
run_id_reg_no_anchors = re.compile("([ESD]R[RS]\d{6,})")

study_id_reg = re.compile("^([ESD]RP\d{6,})$")
run_id_reg = re.compile("^([ESD]R[RS]\d{6,})$")

study_container_reg = re.compile("^([ESD]RP\d{4})$")
run_container_reg = re.compile("^([ESD]R[RS]\d{4})$")


class Assembler(Enum):
    metaspades = 'metaspades'
    spades = 'spades'
    megahit = 'megahit'

    def __str__(self):
        return self.value
