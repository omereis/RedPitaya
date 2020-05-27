#!/bin/bash

GENERATE_CH0_FREQ='25678901'
GENERATE_CH1_FREQ='29012345'
GENERATE_CH0_VALUE='-6'
GENERATE_CH1_VALUE='-6'
SFDR_LEVEL='50'
TEST_STATUS=1

CH0_PEAK_FREQ_MIN=$(bc -l <<< "0.9 * ${GENERATE_CH0_FREQ}")
CH0_PEAK_FREQ_MAX=$(bc -l <<< "1.1 * ${GENERATE_CH0_FREQ}")
CH0_PEAK_VALUE_MIN=$(bc -l <<< "1.1 * ${GENERATE_CH0_VALUE}")
CH0_PEAK_VALUE_MAX=$(bc -l <<< "0.9 * ${GENERATE_CH0_VALUE}")

CH1_PEAK_FREQ_MIN=$(bc -l <<< "0.9 * ${GENERATE_CH1_FREQ}")
CH1_PEAK_FREQ_MAX=$(bc -l <<< "1.1 * ${GENERATE_CH1_FREQ}")
CH1_PEAK_VALUE_MIN=$(bc -l <<< "1.1 * ${GENERATE_CH1_VALUE}")
CH1_PEAK_VALUE_MAX=$(bc -l <<< "0.9 * ${GENERATE_CH1_VALUE}")

export LD_LIBRARY_PATH='/opt/redpitaya/lib'

# Peak measurement
test_peak_measurement() {
    # global in:
    # CH0_PEAK_FREQ_MIN
    # CH0_PEAK_FREQ_MAX
    # CH0_PEAK_VALUE_MIN
    # CH0_PEAK_VALUE_MAX
    # CH1_PEAK_FREQ_MIN
    # CH1_PEAK_FREQ_MAX
    # CH1_PEAK_VALUE_MIN
    # CH1_PEAK_VALUE_MAX
    #
    # global out:
    # CH0_PEAK_FREQ
    # CH0_PEAK_VALUE
    # CH1_PEAK_FREQ
    # CH1_PEAK_VALUE
    local TEST_RESULT=0

    local SPECTRUM_RESULT="$(spectrum -t)"
    CH0_PEAK_FREQ=$(gawk 'match($0, /^ch0 peak\:\s(.+)\sHz\,\s(.+)\sdB$/, a) {print a[1]}' <<< "${SPECTRUM_RESULT}")
    CH0_PEAK_VALUE=$(gawk 'match($0, /^ch0 peak\:\s(.+)\sHz\,\s(.+)\sdB$/, a) {print a[2]}' <<< "${SPECTRUM_RESULT}")
    CH1_PEAK_FREQ=$(gawk 'match($0, /^ch1 peak\:\s(.+)\sHz\,\s(.+)\sdB$/, a) {print a[1]}' <<< "${SPECTRUM_RESULT}")
    CH1_PEAK_VALUE=$(gawk 'match($0, /^ch1 peak\:\s(.+)\sHz\,\s(.+)\sdB$/, a) {print a[2]}' <<< "${SPECTRUM_RESULT}")

    local BC_RESULT=$(bc -l <<< "(${CH0_PEAK_FREQ} >= ${CH0_PEAK_FREQ_MIN}) && (${CH0_PEAK_FREQ} <= ${CH0_PEAK_FREQ_MAX})")
    if [[ "$BC_RESULT" = '1' ]]
    then
        echo "CH0_PEAK_FREQ, meas: ${CH0_PEAK_FREQ}, min: ${CH0_PEAK_FREQ_MIN}, max: ${CH0_PEAK_FREQ_MAX}"
    else
        TEST_RESULT=1
        echo "Error CH0_PEAK_FREQ, meas: ${CH0_PEAK_FREQ}, min: ${CH0_PEAK_FREQ_MIN}, max: ${CH0_PEAK_FREQ_MAX}"
    fi

    BC_RESULT=$(bc -l <<< "(${CH0_PEAK_VALUE} >= ${CH0_PEAK_VALUE_MIN}) && (${CH0_PEAK_VALUE} <= ${CH0_PEAK_VALUE_MAX})")
    if [[ "$BC_RESULT" = '1' ]]
    then
        echo "CH0_PEAK_VALUE, meas: ${CH0_PEAK_VALUE}, min: ${CH0_PEAK_VALUE_MIN}, max: ${CH0_PEAK_VALUE_MAX}"
    else
        TEST_RESULT=1
        echo "Error CH0_PEAK_VALUE, meas: ${CH0_PEAK_VALUE}, min: ${CH0_PEAK_VALUE_MIN}, max: ${CH0_PEAK_VALUE_MAX}"
    fi

    BC_RESULT=$(bc -l <<< "(${CH1_PEAK_FREQ} >= ${CH1_PEAK_FREQ_MIN}) && (${CH1_PEAK_FREQ} <= ${CH1_PEAK_FREQ_MAX})")
    if [[ "$BC_RESULT" = '1' ]]
    then
        echo "CH1_PEAK_FREQ, meas: ${CH1_PEAK_FREQ}, min: ${CH1_PEAK_FREQ_MIN}, max: ${CH1_PEAK_FREQ_MAX}"
    else
        TEST_RESULT=1
        echo "Error CH1_PEAK_FREQ, meas: ${CH1_PEAK_FREQ}, min: ${CH1_PEAK_FREQ_MIN}, max: ${CH1_PEAK_FREQ_MAX}"
    fi

    BC_RESULT=$(bc -l <<< "(${CH1_PEAK_VALUE} >= ${CH1_PEAK_VALUE_MIN}) && (${CH1_PEAK_VALUE} <= ${CH1_PEAK_VALUE_MAX})")
    if [[ "$BC_RESULT" = '1' ]]
    then
        echo "CH1_PEAK_VALUE, meas: ${CH1_PEAK_VALUE}, min: ${CH1_PEAK_VALUE_MIN}, max: ${CH1_PEAK_VALUE_MAX}"
    else
        TEST_RESULT=1
        echo "Error CH1_PEAK_VALUE, meas: ${CH1_PEAK_VALUE}, min: ${CH1_PEAK_VALUE_MIN}, max: ${CH1_PEAK_VALUE_MAX}"
    fi

    return "${TEST_RESULT}"
}

test_sfdr() {
    # global in:
    # SFDR_LEVEL
    # CH0_PEAK_VALUE
    # CH1_PEAK_VALUE
    # CH0_PEAK_FREQ_MIN
    # CH0_PEAK_FREQ_MAX
    # CH1_PEAK_FREQ_MIN
    # CH1_PEAK_FREQ_MAX
    local SPECTRUM_RESULT="$(spectrum -t -m 1 -M 62500000 -C)"
    local CH0_LEVEL=$(bc -l <<< "${CH0_PEAK_VALUE} - ${SFDR_LEVEL}")
    local CH1_LEVEL=$(bc -l <<< "${CH1_PEAK_VALUE} - ${SFDR_LEVEL}")

    spectrum_sfdr_test.py \
        --ch0-freq-min "${CH0_PEAK_FREQ_MIN}" \
        --ch0-freq-max "${CH0_PEAK_FREQ_MAX}" \
        --ch0-level "${CH0_LEVEL}" \
        --ch1-freq-min "${CH1_PEAK_FREQ_MIN}" \
        --ch1-freq-max "${CH1_PEAK_FREQ_MAX}" \
        --ch1-level "${CH1_LEVEL}" \
        <<< "${SPECTRUM_RESULT}"
    return $?
}

# FPGA firmware
cat '/opt/redpitaya/fpga/fpga_0.94.bit' > '/dev/xdevcfg'
sleep 2

# DIO*_P to inputs
monitor 0x40000010 w 0x00
sleep 0.2

# DIO5_N, DIO6_N to outputs
# monitor 0x40000014 w 0x60

# DIO5_N, DIO6_N, DIO7_N to outputs
monitor 0x40000014 w 0xE0
sleep 0.2

# monitor 0x4000001C w 0x60 # DIO5_N = 1, DIO6_N = 1 (IN = external signal)
monitor 0x4000001C w 0xE0 # DIO5_N = 1, DIO6_N = 1, DIO7_N = 1 (IN = external signal, LV)
sleep 1

# Enable generator
generate 1 0.5 "${GENERATE_CH0_FREQ}" sine
generate 2 0.5 "${GENERATE_CH1_FREQ}" sine
sleep 1

echo "SFDR_TEST_EXTERNAL_GEN = " $SFDR_TEST_EXTERNAL_GEN

if [ $SFDR_TEST_EXTERNAL_GEN -eq 1 ] 
then
# Test 1: measurement (external signal)
if test_peak_measurement
then
    echo 'Test 1: SUCCESS'	
else
    echo 'Test 1: FAIL'
    TEST_STATUS=0	
fi

# Test 2: SFDR (external signal)
if test_sfdr
then
    echo 'Test 2: SUCCESS'   
else
    echo 'Test 2: FAIL'
    TEST_STATUS=0
fi

else

# monitor 0x4000001C w 0x20 # DIO5_N = 1, DIO6_N = 0 (IN = OUT)
monitor 0x4000001C w 0xA0 # DIO5_N = 1, DIO6_N = 0, DIO7_N = 1 (IN = OUT, LV)
sleep 1

# Test 3: measurement (output)
if test_peak_measurement
then
    echo 'Test 1: SUCCESS'
else
    echo 'Test 1: FAIL'
    TEST_STATUS=0
fi

# Test 4: SFDR (output)
if test_sfdr
then
    echo 'Test 2: SUCCESS'
else
    echo 'Test 2: FAIL'
    TEST_STATUS=0
fi
fi
# monitor 0x4000001C w 0x00 # DIO5_N = 0, DIO6_N = 0 (IN = GND)
monitor 0x4000001C w 0x80 # DIO5_N = 0, DIO6_N = 0, DIO7_N = 1 (IN = GND, LV)
sleep 1

# Disable generator
generate 1 0 0
generate 2 0 0
exit $TEST_STATUS
