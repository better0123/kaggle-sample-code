import os, os.path
import pandas


TRAIN_DIR           = '../download/train/' 
TEST_DIR            = '../download/test/' 

TRAIN_FEATURES_FILE = '../features/leakage_features_train.csv'
TEST_FEATURES_FILE  = '../features/leakage_features_test.csv'

TRAIN_TEMPLATE_FILE = '../data/train_template.csv'
TEST_TEMPLATE_FILE  = '../download/sampleSubmission.csv'

EXAMPLE_FILENAME    = '20090329_134500_49731s182ms_1.aif'

MOVAVG_WINDOW = 100            # for moving avg feature; optimal ~100
CATEGORICAL_FILESIZES = True   # add categorical fsize variables or not 


def make_train_file_template(filename):
    # make a template file for training data in the 
    # same format as the submission template file
    print "Writing template for training data to:", filename
    fout = open(filename,'w')
    fout.write('clip,probability\n')
    for afile in sorted(os.listdir(TRAIN_DIR)):
        whale_flag = parse_filename(afile)['whale']
        outline = afile + ',' + str(whale_flag)
        fout.write(outline + '\n')
    fout.close()

def parse_filename(filename):
    d = {}
    fname, ext = filename.split('.')
    fields = fname.split('_')
    d['file']   = filename
    d['year']   = fields[0][0:4]
    d['month']  = fields[0][4:6]
    d['day']    = fields[0][6:8]
    d['hour']   = fields[1][0:2]
    d['minute'] = fields[1][2:4]
    d['sec']    = fields[1][4:6]
    d['daysec'] = fields[2].split('s')[0]
    d['daymsec']= fields[2].split('s')[1][:-1]
    d['daymsec_pos0'] = d['daymsec'][-1]
    if len(fields) == 4:  # for training set 
        d['whale'] = fields[3]
    else:
        d['whale'] = -1  # for test set
    return d

def daymsec_nonzero(fname):
    # is the last digit of the millisecond field zero?
    digit = int(parse_filename(fname)['daymsec_pos0'])
    return 1*(digit!=0)

def daymsec(fname):     return int(parse_filename(fname)['daymsec'])
def daysec(fname):      return int(parse_filename(fname)['daysec'])
def whale_heard(fname): return int(parse_filename(fname)['whale'])
def file_size(filename): return int(os.path.getsize(filename))

def expand_var(df, col_name):
    # creates binary variables from a categorical one 
    for elem in df[col_name].unique():
        df[col_name+'_'+str(elem)] = 1*(df[col_name]==elem)
    return df
    # initialize?: df_out = pandas.DataFrame( {'clip':df['clip']} )  

def reverse(a): return a[::-1]

def make_features(template_file, clip_dir): # returns dataframe

    print "Making features using:", template_file
    clip_names = pandas.read_csv(template_file)['clip']
    df = pandas.DataFrame( {'clip':clip_names} )

    df['whale_heard'] = df['clip'].apply(whale_heard)
    df['daysec']      = df['clip'].apply(daysec)

    df['daymsec']     = df['clip'].apply(daymsec)
    df['daymsec_nz1_z0'] = df['clip'].apply(daymsec_nonzero)

    nz = df['daymsec_nz1_z0']
    movavg = pandas.rolling_mean( nz, window=MOVAVG_WINDOW, min_periods=1)
    df['daymsec_nz1_z0_movavg'] = movavg

    # add reverse array? 
    nz_reverse = reverse(df['daymsec_nz1_z0'])
    movavg_reverse = pandas.rolling_mean(nz_reverse, window=MOVAVG_WINDOW, min_periods=1)
    movavg2way = (movavg + reverse(movavg_reverse))/2.0
    df['daymsec_nz1_z0_movavg2way'] = movavg2way 

    df['daymsec_nz1_zmovavg'    ] = nz*1 + (1-nz)*movavg
    df['daymsec_nz1_zmovavg2way'] = nz*1 + (1-nz)*movavg2way

    dir_file_size = lambda f: file_size(clip_dir + f)
    df['fsize'] = df['clip'].apply(dir_file_size)
    if CATEGORICAL_FILESIZES:
        df = expand_var(df, 'fsize')

    return df

def write_features(df, filename):
    print "Writing features with shape", df.shape,"to file:", filename
    df.to_csv(filename, index=False)

def main():
    print "\n*** Leakage Features for Whale Redux ***\n"
    make_train_file_template(TRAIN_TEMPLATE_FILE)

    train_features = make_features(TRAIN_TEMPLATE_FILE, TRAIN_DIR)
    test_features  = make_features(TEST_TEMPLATE_FILE,  TEST_DIR)

    write_features(train_features, TRAIN_FEATURES_FILE)
    write_features(test_features,  TEST_FEATURES_FILE)

    print "Done."
    print "Reminder: Don't forget to run sync_features on the feature files!\n"

if __name__ == '__main__':
    main()

