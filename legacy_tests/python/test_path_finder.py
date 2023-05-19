import os
from src import path_finder

main_dir = 'main_dir'
assembler = 'metaspades'
pf = path_finder.PathFinder(main_dir, assembler)


class TestPathFinder(object):
    def test_get_study_dir(self):
        study_acc = 'ERP001736'
        assert pf.get_study_dir(study_acc) == os.path.join(os.getcwd(), main_dir, 'ERP0017/ERP001736')

    def test_get_run_dir(self):
        study_acc = 'ERP001736'
        run_acc = 'ERR559284'
        study_dir = pf.get_study_dir(study_acc)
        run_dir = pf.get_run_dir(study_dir, run_acc)
        assert run_dir == os.path.join(os.getcwd(), main_dir, 'ERP0017/ERP001736/ERR5592/ERR559284/metaspades/001')

    def test_get_raw_dir(self):
        study_acc = 'ERP001736'
        study_dir = pf.get_study_dir(study_acc)
        assert pf.get_raw_dir(study_dir) == os.path.join(os.getcwd(), main_dir, 'ERP0017/ERP001736/raw')

    def test_get_tmp_dir(self):
        study_acc = 'ERP001736'
        study_dir = pf.get_study_dir(study_acc)
        run_acc = 'ERR559284'
        assert pf.get_tmp_dir(study_dir, run_acc) == os.path.join(os.getcwd(),
                                                                  main_dir, 'ERP0017/ERP001736/tmp/ERR5592/ERR559284/metaspades/001')
    
    def test_get_toil_logfile(self):
        study_acc = 'ERP001736'
        run_acc = 'ERR559284'
        study_dir = pf.get_study_dir(study_acc)
        run_dir = pf.get_run_dir(study_dir, run_acc)
        assert pf.get_toil_log_file(run_dir) == os.path.join(os.getcwd(), main_dir, 'ERP0017/ERP001736/ERR5592/ERR559284/metaspades/001/toil.log')
