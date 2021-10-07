import BigNumber from 'bignumber.js';

export const formatBigNumber = (bigNumVal, decimals = 18, fixed = 3) => {
    if (!bigNumVal) return '';
    return new BigNumber(bigNumVal.toString())
        .dividedBy(new BigNumber(10).pow(decimals))
        .toFormat(fixed);
};

export default formatBigNumber;