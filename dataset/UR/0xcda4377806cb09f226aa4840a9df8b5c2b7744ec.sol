 

pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ManagedToken{
    function setLock(bool _newLockState) public returns (bool success);
    function mint(address _for, uint256 _amount) public returns (bool success);
    function demint(address _for, uint256 _amount) public returns (bool success);
    function decimals() view public returns (uint8 decDigits);
    function totalSupply() view public returns (uint256 supply);
    function balanceOf(address _owner) view public returns (uint256 balance);
}
  
contract HardcodedCrowdsale {
    using SafeMath for uint256;

     

    enum ICOStateEnum {NotStarted, Started, Refunded, Successful}

    address public owner = msg.sender;
    ManagedToken public managedTokenLedger;

    string public name = "Uservice Token";
    string public symbol = "UST";

    bool public halted = false;
     
    uint256 public minWeiToBuy = 200000000000000000;           
    
    uint256 public preICOcontributors = 0;

    uint256 public preICOstart;
    uint256 public preICOend;
    uint256 public preICOgoal;
    uint256 public preICOcollected = 0;
    uint256 public preICOcap = 10000 ether;
    uint256 public preICOtokensSold = 0;
    ICOStateEnum public preICOstate = ICOStateEnum.NotStarted;
    
    uint8 public decimals = 18;
    uint256 public DECIMAL_MULTIPLIER = 10**uint256(decimals);

    uint8 public saleIndex = 0;
 
    uint256 public preICOprice = uint256(0.25 ether).div(1000);
    uint256[3] public preICOcoinsLeft = [40000000*DECIMAL_MULTIPLIER, 0*DECIMAL_MULTIPLIER, 0*DECIMAL_MULTIPLIER];

    mapping(address => uint256) public weiForRefundPreICO;

    mapping(address => uint256) public weiToRecoverPreICO;

    mapping(address => uint256) public balancesForPreICO;

    event Purchased(address indexed _from, uint256 _value);

    function advanceState() public returns (bool success) {
        transitionState();
        return true;
    }

    function transitionState() internal {
        if (now >= preICOstart) {
            if (preICOstate == ICOStateEnum.NotStarted) {
                preICOstate = ICOStateEnum.Started;
            }
            if (preICOcap > 0 && preICOcollected >= preICOcap) {
                preICOstate = ICOStateEnum.Successful;
            }
            if ( (saleIndex == preICOcoinsLeft.length) && (preICOcoinsLeft[saleIndex-1] == 0) ) {
                preICOstate = ICOStateEnum.Successful;
            }
        } if (now >= preICOend) {
            if (preICOstate == ICOStateEnum.Started) {
                if (preICOcollected >= preICOgoal) {
                    preICOstate = ICOStateEnum.Successful;
                } else {
                    preICOstate = ICOStateEnum.Refunded;
                }
            }
        } 
    }

    modifier stateTransition() {
        transitionState();
        _;
        transitionState();
    }

    modifier notHalted() {
        require(!halted);
        _;
    }

     

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));      
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return managedTokenLedger.balanceOf(_owner);
    }

    function totalSupply() view public returns (uint256 balance) {
        return managedTokenLedger.totalSupply();
    }


    function HardcodedCrowdsale (uint _preICOstart, uint _preICOend, uint _preICOgoal, uint _preICOcap, address _newLedgerAddress) public {
 
        require(_preICOend > _preICOstart);
        require(_preICOgoal > 0);
        require(_newLedgerAddress != address(0));
        preICOstart = _preICOstart;
        preICOend = _preICOend;
        preICOgoal = _preICOgoal;
        preICOcap = _preICOcap;
        managedTokenLedger = ManagedToken(_newLedgerAddress);
        assert(managedTokenLedger.decimals() == decimals);
    }

    function setNameAndTicker(string _name, string _symbol) onlyOwner public returns (bool success) {
        require(bytes(_name).length > 1);
        require(bytes(_symbol).length > 1);
        name = _name;
        symbol = _symbol;
        return true;
    }

    function setLedger (address _newLedgerAddress) onlyOwner public returns (bool success) {
        require(_newLedgerAddress != address(0));
        managedTokenLedger = ManagedToken(_newLedgerAddress);
        assert(managedTokenLedger.decimals() == decimals);
        return true;
    }

    function () payable stateTransition notHalted external {
        require(msg.value > 0);
        require(preICOstate == ICOStateEnum.Started);
        assert(preICOBuy());
    }

    
    function finalize() stateTransition public returns (bool success) {
        require(preICOstate == ICOStateEnum.Successful);
        owner.transfer(preICOcollected);
        return true;
    }

    function setHalt(bool _halt) onlyOwner public returns (bool success) {
        halted = _halt;
        return true;
    }

    function calculateAmountBoughtPreICO(uint256 _weisSentScaled)
        internal returns (uint256 _tokensToBuyScaled, uint256 _weisLeftScaled) {
        uint256 value = _weisSentScaled;
        uint256 totalPurchased = 0;
        for (uint8 i = saleIndex; i < preICOcoinsLeft.length; i++) {
            if (preICOcoinsLeft[i] == 0) {
                continue;
            }
            uint256 forThisRate = value.div(preICOprice);
            if (forThisRate == 0) {
                break;
            }
            if (forThisRate >= preICOcoinsLeft[i]) {
                forThisRate = preICOcoinsLeft[i];
                preICOcoinsLeft[i] = 0;
                saleIndex = i+1;
            } else {
                preICOcoinsLeft[i] = preICOcoinsLeft[i].sub(forThisRate);
            }
            uint256 consumed = forThisRate.mul(preICOprice);
            value = value.sub(consumed);
            totalPurchased = totalPurchased.add(forThisRate);
        }
        return (totalPurchased, value);
    }

    function preICOBuy() internal notHalted returns (bool success) {
        uint256 weisSentScaled = msg.value.mul(DECIMAL_MULTIPLIER);
        address _for = msg.sender;
        var (tokensBought, fundsLeftScaled) = calculateAmountBoughtPreICO(weisSentScaled);
        uint256 fundsLeft = fundsLeftScaled.div(DECIMAL_MULTIPLIER);
        uint256 totalSpent = msg.value.sub(fundsLeft);
        if (totalSpent < minWeiToBuy) {
            revert();
        }
        if (balanceOf(_for) == 0) {
            preICOcontributors = preICOcontributors + 1;
        }
        managedTokenLedger.mint(_for, tokensBought);
        balancesForPreICO[_for] = balancesForPreICO[_for].add(tokensBought);
        weiForRefundPreICO[_for] = weiForRefundPreICO[_for].add(totalSpent);
        weiToRecoverPreICO[_for] = weiToRecoverPreICO[_for].add(fundsLeft);
        Purchased(_for, tokensBought);
        preICOcollected = preICOcollected.add(totalSpent);
        preICOtokensSold = preICOtokensSold.add(tokensBought);
        return true;
    }

    function recoverLeftoversPreICO() stateTransition notHalted public returns (bool success) {
        require(preICOstate != ICOStateEnum.NotStarted);
        uint256 value = weiToRecoverPreICO[msg.sender];
        delete weiToRecoverPreICO[msg.sender];
        msg.sender.transfer(value);
        return true;
    }

    function refundPreICO() stateTransition notHalted public returns (bool success) {
        require(preICOstate == ICOStateEnum.Refunded);
        uint256 value = weiForRefundPreICO[msg.sender];
        delete weiForRefundPreICO[msg.sender];
        uint256 tokenValue = balancesForPreICO[msg.sender];
        delete balancesForPreICO[msg.sender];
        managedTokenLedger.demint(msg.sender, tokenValue);
        msg.sender.transfer(value);
        return true;
    }

    function cleanup() onlyOwner public {
        selfdestruct(owner);
    }

}