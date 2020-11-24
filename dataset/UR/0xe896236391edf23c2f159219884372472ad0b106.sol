 

 
pragma solidity ^0.4.16;

 
contract Token {
     
    function totalSupply () constant returns (uint256 supply);

     
    function balanceOf (address _owner) constant returns (uint256 balance);

     
    function transfer (address _to, uint256 _value) returns (bool success);

     
    function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success);

     
    function approve (address _spender, uint256 _value) returns (bool success);

     
    function allowance (address _owner, address _spender) constant
    returns (uint256 remaining);

     
    event Transfer (address indexed _from, address indexed _to, uint256 _value);

     
    event Approval (
        address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract SafeMath {
    uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    function safeAdd (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
        assert (x <= MAX_UINT256 - y);
        return x + y;
    }

     
    function safeSub (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
        assert (x >= y);
        return x - y;
    }

     
    function safeMul (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
        if (y == 0) return 0;  
        assert (x <= MAX_UINT256 / y);
        return x * y;
    }
}

 
contract Math is SafeMath {
     
    uint128 internal constant TWO127 = 0x80000000000000000000000000000000;

     
    uint128 internal constant TWO128_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    uint256 internal constant TWO128 = 0x100000000000000000000000000000000;

     
    uint256 internal constant TWO256_1 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    uint256 internal constant TWO255 =
    0x8000000000000000000000000000000000000000000000000000000000000000;

     
    int256 internal constant MINUS_TWO255 =
    -0x8000000000000000000000000000000000000000000000000000000000000000;

     
    int256 internal constant TWO255_1 =
    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    uint128 internal constant LN2 = 0xb17217f7d1cf79abc9e3b39803f2f6af;

     
    function mostSignificantBit (uint256 x) pure internal returns (uint8) {
        require (x > 0);

        uint8 l = 0;
        uint8 h = 255;

        while (h > l) {
            uint8 m = uint8 ((uint16 (l) + uint16 (h)) >> 1);
            uint256 t = x >> m;
            if (t == 0) h = m - 1;
            else if (t > 1) l = m + 1;
            else return m;
        }

        return h;
    }

     
    function log_2 (uint256 x) pure internal returns (int256) {
        require (x > 0);

        uint8 msb = mostSignificantBit (x);

        if (msb > 128) x >>= msb - 128;
        else if (msb < 128) x <<= 128 - msb;

        x &= TWO128_1;

        int256 result = (int256 (msb) - 128) << 128;  

        int256 bit = TWO127;
        for (uint8 i = 0; i < 128 && x > 0; i++) {
            x = (x << 1) + ((x * x + TWO127) >> 128);
            if (x > TWO128_1) {
                result |= bit;
                x = (x >> 1) - TWO127;
            }
            bit >>= 1;
        }

        return result;
    }

     
    function ln (uint256 x) pure internal returns (int256) {
        require (x > 0);

        int256 l2 = log_2 (x);
        if (l2 == 0) return 0;
        else {
            uint256 al2 = uint256 (l2 > 0 ? l2 : -l2);
            uint8 msb = mostSignificantBit (al2);
            if (msb > 127) al2 >>= msb - 127;
            al2 = (al2 * LN2 + TWO127) >> 128;
            if (msb > 127) al2 <<= msb - 127;

            return int256 (l2 >= 0 ? al2 : -al2);
        }
    }

     
    function fpMul (uint256 x, uint256 y) pure internal returns (uint256) {
        uint256 xh = x >> 128;
        uint256 xl = x & TWO128_1;
        uint256 yh = y >> 128;
        uint256 yl = y & TWO128_1;

        uint256 result = xh * yh;
        require (result <= TWO128_1);
        result <<= 128;

        result = safeAdd (result, xh * yl);
        result = safeAdd (result, xl * yh);
        result = safeAdd (result, (xl * yl) >> 128);

        return result;
    }

     
    function longMul (uint256 x, uint256 y)
    pure internal returns (uint256 h, uint256 l) {
        uint256 xh = x >> 128;
        uint256 xl = x & TWO128_1;
        uint256 yh = y >> 128;
        uint256 yl = y & TWO128_1;

        h = xh * yh;
        l = xl * yl;

        uint256 m1 = xh * yl;
        uint256 m2 = xl * yh;

        h += m1 >> 128;
        h += m2 >> 128;

        m1 <<= 128;
        m2 <<= 128;

        if (l > TWO256_1 - m1) h += 1;
        l += m1;

        if (l > TWO256_1 - m2) h += 1;
        l += m2;
    }

     
    function fpMulI (int256 x, int256 y) pure internal returns (int256) {
        bool negative = (x ^ y) < 0;  

        uint256 result = fpMul (
            x < 0 ? uint256 (-1 - x) + 1 : uint256 (x),
            y < 0 ? uint256 (-1 - y) + 1 : uint256 (y));

        if (negative) {
            require (result <= TWO255);
            return result == 0 ? 0 : -1 - int256 (result - 1);
        } else {
            require (result < TWO255);
            return int256 (result);
        }
    }

     
    function safeAddI (int256 x, int256 y) pure internal returns (int256) {
        if (x < 0 && y < 0)
            assert (x >= MINUS_TWO255 - y);

        if (x > 0 && y > 0)
            assert (x <= TWO255_1 - y);

        return x + y;
    }

     
    function fpDiv (uint256 x, uint256 y) pure internal returns (uint256) {
        require (y > 0);  

        uint8 maxShiftY = mostSignificantBit (y);
        if (maxShiftY >= 128) maxShiftY -= 127;
        else maxShiftY = 0;

        uint256 result = 0;

        while (true) {
            uint256 rh = x >> 128;
            uint256 rl = x << 128;

            uint256 ph;
            uint256 pl;

            (ph, pl) = longMul (result, y);
            if (rl < pl) {
                ph = safeAdd (ph, 1);
            }

            rl -= pl;
            rh -= ph;

            if (rh == 0) {
                result = safeAdd (result, rl / y);
                break;
            } else {
                uint256 reminder = (rh << 128) + (rl >> 128);

                 
                uint8 shiftReminder = 255 - mostSignificantBit (reminder);
                if (shiftReminder > 128) shiftReminder = 128;

                 
                uint8 shiftResult = 128 - shiftReminder;

                 
                uint8 shiftY = maxShiftY;
                if (shiftY > shiftResult) shiftY = shiftResult;

                shiftResult -= shiftY;

                uint256 r = (reminder << shiftReminder) / (((y - 1) >> shiftY) + 1);

                uint8 msbR = mostSignificantBit (r);
                require (msbR <= 255 - shiftResult);

                result = safeAdd (result, r << shiftResult);
            }
        }

        return result;
    }
}


 
contract PATTokenSale is Math {
     
    uint256 private constant TRIPLE_BONUS = 1 hours;

     
    uint256 private constant DOUBLE_BONUS = 1 days;

     
    uint256 private constant SINGLE_BONUS = 1 weeks;

     
    function PATTokenSale (
        uint256 _saleStartTime, uint256 _saleDuration,
        Token _token, address _centralBank,
        uint256 _saleCap, uint256 _minimumInvestment,
        int256 _a, int256 _b, int256 _c) {
        saleStartTime = _saleStartTime;
        saleDuration = _saleDuration;
        token = _token;
        centralBank = _centralBank;
        saleCap = _saleCap;
        minimumInvestment = _minimumInvestment;
        a = _a;
        b = _b;
        c = _c;
    }

     
    function () payable public {
        require (msg.data.length == 0);

        buy ();
    }

     
    function buy () payable public {
        require (!finished);
        require (now >= saleStartTime);
        require (now < safeAdd (saleStartTime, saleDuration));

        require (msg.value >= minimumInvestment);

        if (msg.value > 0) {
            uint256 remainingCap = safeSub (saleCap, totalInvested);
            uint256 toInvest;
            uint256 toRefund;

            if (msg.value <= remainingCap) {
                toInvest = msg.value;
                toRefund = 0;
            } else {
                toInvest = remainingCap;
                toRefund = safeSub (msg.value, toInvest);
            }

            Investor storage investor = investors [msg.sender];
            investor.amount = safeAdd (investor.amount, toInvest);
            if (now < safeAdd (saleStartTime, TRIPLE_BONUS))
                investor.bonusAmount = safeAdd (
                    investor.bonusAmount, safeMul (toInvest, 6));
            else if (now < safeAdd (saleStartTime, DOUBLE_BONUS))
                investor.bonusAmount = safeAdd (
                    investor.bonusAmount, safeMul (toInvest, 4));
            else if (now < safeAdd (saleStartTime, SINGLE_BONUS))
                investor.bonusAmount = safeAdd (
                    investor.bonusAmount, safeMul (toInvest, 2));

            Investment (msg.sender, toInvest);

            totalInvested = safeAdd (totalInvested, toInvest);
            if (toInvest == remainingCap) {
                finished = true;
                finalPrice = price (now);

                Finished (finalPrice);
            }

            if (toRefund > 0)
                msg.sender.transfer (toRefund);
        }
    }

     
    function buyReferral (address _referralCode) payable public {
        require (msg.sender != _referralCode);

        Investor storage referee = investors [_referralCode];

         
        require (referee.amount > 0);

        Investor storage referrer = investors [msg.sender];
        uint256 oldAmount = referrer.amount;

        buy ();

        uint256 invested = safeSub (referrer.amount, oldAmount);

         
        require (invested > 0);

        referee.investedByReferrers = safeAdd (
            referee.investedByReferrers, invested);

        referrer.bonusAmount = safeAdd (
            referrer.bonusAmount,
            min (referee.amount, invested));
    }

     
    function outstandingTokens (address _investor)
    constant public returns (uint256) {
        require (finished);
        assert (finalPrice > 0);

        Investor storage investor = investors [_investor];
        uint256 bonusAmount = investor.bonusAmount;
        bonusAmount = safeAdd (
            bonusAmount, min (investor.amount, investor.investedByReferrers));

        uint256 effectiveAmount = safeAdd (
            investor.amount,
            bonusAmount / 40);

        return fpDiv (effectiveAmount, finalPrice);
    }

     
    function deliver (address _investor) public returns (bool) {
        require (finished);

        Investor storage investor = investors [_investor];
        require (investor.amount > 0);

        uint256 value = outstandingTokens (_investor);
        if (value > 0) {
            if (!token.transferFrom (centralBank, _investor, value)) return false;
        }

        totalInvested = safeSub (totalInvested, investor.amount);
        investor.amount = 0;
        investor.bonusAmount = 0;
        investor.investedByReferrers = 0;
        return true;
    }

     
    function collectRevenue () public {
        require (msg.sender == centralBank);

        centralBank.transfer (this.balance);
    }

     
    function price (uint256 _time) constant public returns (uint256) {
        require (_time >= saleStartTime);
        require (_time <= safeAdd (saleStartTime, saleDuration));

        require (_time <= TWO128_1);
        uint256 t = _time << 128;

        uint256 cPlusT = (c >= 0) ?
        safeAdd (t, uint256 (c)) :
        safeSub (t, uint256 (-1 - c) + 1);
        int256 lnCPlusT = ln (cPlusT);
        int256 bLnCPlusT = fpMulI (b, lnCPlusT);
        int256 aPlusBLnCPlusT = safeAddI (a, bLnCPlusT);

        require (aPlusBLnCPlusT >= 0);
        return uint256 (aPlusBLnCPlusT);
    }

     
    function finishSale () public {
        require (msg.sender == centralBank);
        require (!finished);
        uint256 saleEndTime = safeAdd (saleStartTime, saleDuration);
        require (now >= saleEndTime);

        finished = true;
        finalPrice = price (saleEndTime);

        Finished (finalPrice);
    }

     
    function destroy () public {
        require (msg.sender == centralBank);
        require (finished);
        require (now >= safeAdd (saleStartTime, saleDuration));
        require (totalInvested == 0);
        require (this.balance == 0);

        selfdestruct (centralBank);
    }

     
    function min (uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

     
    uint256 internal saleStartTime;

     
    uint256 internal saleDuration;

     
    Token internal token;

     
    address internal centralBank;

     
    uint256 internal saleCap;

     
    uint256 internal minimumInvestment;

     
    int256 internal a;
    int256 internal b;
    int256 internal c;

     
    bool internal finished = false;

     
    uint256 internal finalPrice;

     
    mapping (address => Investor) internal investors;

     
    uint256 internal totalInvested = 0;

     
    struct Investor {
         
        uint256 amount;

         
        uint256 bonusAmount;

         
        uint256 investedByReferrers;
    }

     
    event Investment (address indexed investor, uint256 amount);

     
    event Finished (uint256 finalPrice);
}