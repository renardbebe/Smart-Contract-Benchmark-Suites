 

pragma solidity ^0.4.11;
contract SafeMath {
    
     

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

     


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


     

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

     

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

     

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

 
 
contract Owned {
     
     
    modifier onlyOwner() {
        require(msg.sender == owner) ;
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract Contribution is SafeMath, Owned {
    uint256 public constant MIN_FUND = (0.01 ether);
    uint256 public constant CRAWDSALE_START_DAY = 1;
    uint256 public constant CRAWDSALE_END_DAY = 7;

    uint256 public dayCycle = 24 hours;
    uint256 public fundingStartTime = 0;
    address public ethFundDeposit = 0;
    address public investorDeposit = 0;
    bool public isFinalize = false;
    bool public isPause = false;
    mapping (uint => uint) public dailyTotals;  
    mapping (uint => mapping (address => uint)) public userBuys;  
    uint256 public totalContributedETH = 0;  

     
    event LogBuy (uint window, address user, uint amount);
    event LogCreate (address ethFundDeposit, address investorDeposit, uint fundingStartTime, uint dayCycle);
    event LogFinalize (uint finalizeTime);
    event LogPause (uint finalizeTime, bool pause);

    function Contribution (address _ethFundDeposit, address _investorDeposit, uint256 _fundingStartTime, uint256 _dayCycle)  {
        require( now < _fundingStartTime );
        require( _ethFundDeposit != address(0) );

        fundingStartTime = _fundingStartTime;
        dayCycle = _dayCycle;
        ethFundDeposit = _ethFundDeposit;
        investorDeposit = _investorDeposit;
        LogCreate(_ethFundDeposit, _investorDeposit, _fundingStartTime,_dayCycle);
    }

     
    function () payable {  
        require(!isPause);
        require(!isFinalize);
        require( msg.value >= MIN_FUND );  

        ethFundDeposit.transfer(msg.value);
        buy(today(), msg.sender, msg.value);
    }

    function importExchangeSale(uint256 day, address _exchangeAddr, uint _amount) onlyOwner {
        buy(day, _exchangeAddr, _amount);
    }

    function buy(uint256 day, address _addr, uint256 _amount) internal {
        require( day >= CRAWDSALE_START_DAY && day <= CRAWDSALE_END_DAY ); 

         
        userBuys[day][_addr] += _amount;
        dailyTotals[day] += _amount;
        totalContributedETH += _amount;

        LogBuy(day, _addr, _amount);
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }

    function pause(bool _isPause) onlyOwner {
        isPause = _isPause;
        LogPause(now,_isPause);
    }

    function finalize() onlyOwner {
        isFinalize = true;
        LogFinalize(now);
    }

    function today() constant returns (uint) {
        return sub(now, fundingStartTime) / dayCycle + 1;
    }
}