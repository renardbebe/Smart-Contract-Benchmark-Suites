 

pragma solidity ^0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract AddressWhitelist is Ownable {
     
    mapping (address => bool) public whitelisted;

    function AddressWhitelist() public {
    }

    function isWhitelisted(address addr) view public returns (bool) {
        return whitelisted[addr];
    }

    event LogWhitelistAdd(address indexed addr);

     
    function addToWhitelist(address[] addresses) public onlyOwner returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (!whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = true;
                LogWhitelistAdd(addresses[i]);
            }
        }

        return true;
    }

    event LogWhitelistRemove(address indexed addr);

     
    function removeFromWhitelist(address[] addresses) public onlyOwner returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = false;
                LogWhitelistRemove(addresses[i]);
            }
        }

        return true;
    }
}

 

contract KnowsTime {
    function KnowsTime() public {
    }

    function currentTime() public view returns (uint) {
        return now;
    }
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract BntyExchangeRateCalculator is KnowsTime, Ownable {
    using SafeMath for uint;

    uint public constant WEI_PER_ETH = 10 ** 18;

    uint public constant MICRODOLLARS_PER_DOLLAR = 10 ** 6;

    uint public bntyMicrodollarPrice;

    uint public USDEtherPrice;

    uint public fixUSDPriceTime;

     
    function BntyExchangeRateCalculator(uint _bntyMicrodollarPrice, uint _USDEtherPrice, uint _fixUSDPriceTime)
        public
    {
        require(_bntyMicrodollarPrice > 0);
        require(_USDEtherPrice > 0);

        bntyMicrodollarPrice = _bntyMicrodollarPrice;
        fixUSDPriceTime = _fixUSDPriceTime;
        USDEtherPrice = _USDEtherPrice;
    }

     
    function setUSDEtherPrice(uint _USDEtherPrice) onlyOwner public {
        require(currentTime() < fixUSDPriceTime);
        require(_USDEtherPrice > 0);

        USDEtherPrice = _USDEtherPrice;
    }

     
    function usdToWei(uint usd) view public returns (uint) {
        return WEI_PER_ETH.mul(usd).div(USDEtherPrice);
    }

     
    function weiToBnty(uint amtWei) view public returns (uint) {
        return USDEtherPrice.mul(MICRODOLLARS_PER_DOLLAR).mul(amtWei).div(bntyMicrodollarPrice);
    }
}

 

contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

 

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

 

 

 
 
 
 
 
 
 




contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.2';  


     
     
     
    struct  Checkpoint {

         
        uint128 fromBlock;

         
        uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


 
 
 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         

         
         
        if (msg.sender != controller) {
            require(transfersEnabled);

             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

            
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           Transfer(_from, _to, _amount);

           return true;
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
     
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


 
 
 

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

         
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

         
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

 
 
 

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

 

contract Bounty0xToken is MiniMeToken {
    function Bounty0xToken(address _tokenFactory)
        MiniMeToken(
            _tokenFactory,
            0x0,                         
            0,                           
            "Bounty0x Token",            
            18   ,                       
            "BNTY",                      
            false                        
        )
        public
    {
    }

     
    function generateTokensAll(address[] _owners, uint[] _amounts) onlyController public {
        require(_owners.length == _amounts.length);

        for (uint i = 0; i < _owners.length; i++) {
            require(generateTokens(_owners[i], _amounts[i]));
        }
    }
}

 

 
contract KnowsConstants {
     
    uint public constant FIXED_PRESALE_USD_ETHER_PRICE = 355;
    uint public constant MICRO_DOLLARS_PER_BNTY_MAINSALE = 16500;
    uint public constant MICRO_DOLLARS_PER_BNTY_PRESALE = 13200;

     
    uint public constant HARD_CAP_USD = 1500000;                            
    uint public constant MAXIMUM_CONTRIBUTION_WHITELIST_PERIOD_USD = 1500;  
    uint public constant MAXIMUM_CONTRIBUTION_LIMITED_PERIOD_USD = 10000;   
    uint public constant MAX_GAS_PRICE = 70 * (10 ** 9);                    
    uint public constant MAX_GAS = 500000;                                  

     
    uint public constant SALE_START_DATE = 1513346400;                     
    uint public constant WHITELIST_END_DATE = SALE_START_DATE + 24 hours;  
    uint public constant LIMITS_END_DATE = SALE_START_DATE + 48 hours;     
    uint public constant SALE_END_DATE = SALE_START_DATE + 4 weeks;        
    uint public constant UNFREEZE_DATE = SALE_START_DATE + 76 weeks;       

    function KnowsConstants() public {}
}

 

 
interface Bounty0xPresaleI {
    function balanceOf(address addr) public returns (uint balance);
}

 

 

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
contract Bounty0xPresaleDistributor is KnowsConstants, BntyExchangeRateCalculator {
    using SafeMath for uint;

    Bounty0xPresaleI public deployedPresaleContract;
    Bounty0xToken public bounty0xToken;

    mapping(address => uint) public tokensPaid;

    function Bounty0xPresaleDistributor(Bounty0xToken _bounty0xToken, Bounty0xPresaleI _deployedPresaleContract)
        BntyExchangeRateCalculator(MICRO_DOLLARS_PER_BNTY_PRESALE, FIXED_PRESALE_USD_ETHER_PRICE, 0)
        public
    {
        bounty0xToken = _bounty0xToken;
        deployedPresaleContract = _deployedPresaleContract;
    }

    event OnPreSaleBuyerCompensated(address indexed contributor, uint numTokens);

     
    function compensatePreSaleInvestors(address[] preSaleInvestors) public {
         
        for (uint i = 0; i < preSaleInvestors.length; i++) {
            address investorAddress = preSaleInvestors[i];

             
            uint weiContributed = deployedPresaleContract.balanceOf(investorAddress);

             
            if (weiContributed > 0 && tokensPaid[investorAddress] == 0) {
                 
                uint bntyCompensation = Math.min256(weiToBnty(weiContributed), bounty0xToken.balanceOf(this));

                 
                tokensPaid[investorAddress] = bntyCompensation;

                 
                require(bounty0xToken.transfer(investorAddress, bntyCompensation));

                 
                OnPreSaleBuyerCompensated(investorAddress, bntyCompensation);
            }
        }
    }
}

 

 
contract Bounty0xReserveHolder is KnowsConstants, KnowsTime {
     
    Bounty0xToken public token;

     
    address public beneficiary;

    function Bounty0xReserveHolder(Bounty0xToken _token, address _beneficiary) public {
        require(_token != address(0));
        require(_beneficiary != address(0));

        token = _token;
        beneficiary = _beneficiary;
    }

     
    function release() public {
        require(currentTime() >= UNFREEZE_DATE);

        uint amount = token.balanceOf(this);
        require(amount > 0);

        require(token.transfer(beneficiary, amount));
    }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

contract Bounty0xCrowdsale is KnowsTime, KnowsConstants, Ownable, BntyExchangeRateCalculator, AddressWhitelist, Pausable {
    using SafeMath for uint;

     
    Bounty0xToken public bounty0xToken;                                  

     
    mapping (address => uint) public contributionAmounts;             
    uint public totalContributions;                                   

     
    event OnContribution(address indexed contributor, bool indexed duringWhitelistPeriod, uint indexed contributedWei, uint bntyAwarded, uint refundedWei);
    event OnWithdraw(address to, uint amount);

    function Bounty0xCrowdsale(Bounty0xToken _bounty0xToken, uint _USDEtherPrice)
        BntyExchangeRateCalculator(MICRO_DOLLARS_PER_BNTY_MAINSALE, _USDEtherPrice, SALE_START_DATE)
        public
    {
        bounty0xToken = _bounty0xToken;
    }

     
    function withdraw(uint amount) public onlyOwner {
        msg.sender.transfer(amount);
        OnWithdraw(msg.sender, amount);
    }

     
    function () payable public whenNotPaused {
        uint time = currentTime();

         
        require(time >= SALE_START_DATE);

         
        require(time < SALE_END_DATE);

         
        uint maximumContribution = usdToWei(HARD_CAP_USD).sub(totalContributions);

         
        bool isDuringWhitelistPeriod = time < WHITELIST_END_DATE;

         
        if (time < LIMITS_END_DATE) {
             
            require(tx.gasprice <= MAX_GAS_PRICE);

             
            require(msg.gas <= MAX_GAS);

             
            if (isDuringWhitelistPeriod) {
                require(isWhitelisted(msg.sender));

                 
                maximumContribution = Math.min256(
                    maximumContribution,
                    usdToWei(MAXIMUM_CONTRIBUTION_WHITELIST_PERIOD_USD).sub(contributionAmounts[msg.sender])
                );
            } else {
                 
                maximumContribution = Math.min256(
                    maximumContribution,
                    usdToWei(MAXIMUM_CONTRIBUTION_LIMITED_PERIOD_USD).sub(contributionAmounts[msg.sender])
                );
            }
        }

         
        uint contribution = Math.min256(msg.value, maximumContribution);
        uint refundWei = msg.value.sub(contribution);

         
        require(contribution > 0);

         
        totalContributions = totalContributions.add(contribution);

         
        contributionAmounts[msg.sender] = contributionAmounts[msg.sender].add(contribution);

         
        uint amountBntyRewarded = Math.min256(weiToBnty(contribution), bounty0xToken.balanceOf(this));
        require(bounty0xToken.transfer(msg.sender, amountBntyRewarded));

        if (refundWei > 0) {
            msg.sender.transfer(refundWei);
        }

         
        OnContribution(msg.sender, isDuringWhitelistPeriod, contribution, amountBntyRewarded, refundWei);
    }
}

 

contract CrowdsaleTokenController is Ownable, AddressWhitelist, TokenController {
    bool public whitelistOff;
    Bounty0xToken public token;

    function CrowdsaleTokenController(Bounty0xToken _token) public {
        token = _token;
    }

     
    function setWhitelistOff(bool _whitelistOff) public onlyOwner {
        whitelistOff = _whitelistOff;
    }

     
    function changeController(address newController) public onlyOwner {
        token.changeController(newController);
    }

     
    function enableTransfers(bool _transfersEnabled) public onlyOwner {
        token.enableTransfers(_transfersEnabled);
    }

     
     
     
    function proxyPayment(address _owner) public payable returns (bool) {
        return false;
    }

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
        return whitelistOff || isWhitelisted(_from);
    }

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
        return whitelistOff || isWhitelisted(_owner);
    }
}