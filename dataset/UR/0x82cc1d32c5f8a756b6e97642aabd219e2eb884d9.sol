 

pragma solidity ^0.4.24;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract ReentrancyGuard {

   
   
  uint private constant REENTRANCY_GUARD_FREE = 1;

   
  uint private constant REENTRANCY_GUARD_LOCKED = 2;

   
  uint private reentrancyLock = REENTRANCY_GUARD_FREE;

   
  modifier nonReentrant() {
    require(reentrancyLock == REENTRANCY_GUARD_FREE);
    reentrancyLock = REENTRANCY_GUARD_LOCKED;
    _;
    reentrancyLock = REENTRANCY_GUARD_FREE;
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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

 
 
 
contract MiniMeToken is Ownable {

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

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
    constructor(
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
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
         
        if (msg.sender != owner) {
            require(transfersEnabled);

             
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

           if (_amount == 0) {
               emit Transfer(_from, _to, _amount);     
               return;
           }

           require(parentSnapShotBlock < block.number);

            
           require((_to != 0) && (_to != address(this)));

            
            
           uint previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

            
           if (isContract(owner)) {
               require(TokenController(owner).onTransfer(_from, _to, _amount));
           }

            
            
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

            
            
           uint previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo);  
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

            
           emit Transfer(_from, _to, _amount);

    }

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

         
        if (isContract(owner)) {
            require(TokenController(owner).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
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

        cloneToken.transferOwnership(msg.sender);

         
        emit NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) public onlyOwner returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyOwner public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, 0, _amount);
        return true;
    }

 
 
 


     
     
    function enableTransfers(bool _transfersEnabled) public onlyOwner {
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
        require(isContract(owner));
        require(TokenController(owner).proxyPayment.value(msg.value)(msg.sender));
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }

 
 
 
    event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {
    event CreatedToken(string symbol, address addr);

     
     
     
     
     
     
     
     
     
     
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

        newToken.transferOwnership(msg.sender);
        emit CreatedToken(_tokenSymbol, address(newToken));
        return newToken;
    }
}

 
interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, DetailedERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(DetailedERC20 src, DetailedERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(DetailedERC20 src, uint srcAmount, DetailedERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}


contract IAO is Ownable, ReentrancyGuard, TokenController {
    using SafeMath for uint256;

    modifier onlyActive {
        require(isActive, "IAO is not active");
        _;
    }

    DetailedERC20 constant internal ETH_TOKEN_ADDRESS = DetailedERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    uint256 constant PRECISION = 10 ** 18;  
    uint256 constant MAX_DONATION = 100 * (10 ** 18);  
    uint256 constant KRO_RATE = 5 * (10 ** 17);  
    uint256 constant REFERRAL_BONUS = 10 * (10 ** 16);  
    address constant DAI_ADDR = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address constant KYBER_ADDR = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;

    address public kroAddr;
    address public beneficiary;
    bytes32 public secretHash;
    bool public isActive;

    event Register(address indexed _manager, uint256 indexed _block, uint256 _donationInDAI);


     

    constructor (address _kroAddr, address _beneficiary, bytes32 _secretHash) public {
        kroAddr = _kroAddr;
        beneficiary = _beneficiary;
        secretHash = _secretHash;
    }
    

    function setActive(bool _isActive) onlyOwner public {
        isActive = _isActive;
    }


    function transferKROContractOwnership(address _newOwner, string _secret) public onlyOwner {
        require(!isActive, "IAO is not over");  
        require(keccak256(abi.encodePacked(_secret)) == secretHash, "Secret incorrect");  

         
        Ownable kro = Ownable(kroAddr);
        kro.transferOwnership(_newOwner);
    }


    function _register(uint256 _donationInDAI, address _referrer) internal onlyActive {
        require(_donationInDAI > 0 && _donationInDAI <= MAX_DONATION, "Donation out of range");
        require(_referrer != msg.sender, "Can't refer self");

        MiniMeToken kro = MiniMeToken(kroAddr);
        require(kro.balanceOf(msg.sender) == 0, "Already joined");  

         
        uint256 kroAmount = _donationInDAI.mul(KRO_RATE).div(PRECISION);
        require(kro.generateTokens(msg.sender, kroAmount), "Failed minting");

         
        if (_referrer != address(0) && kro.balanceOf(_referrer) > 0) {
            uint256 bonusAmount = kroAmount.mul(REFERRAL_BONUS).div(PRECISION);
            require(kro.generateTokens(msg.sender, bonusAmount), "Failed minting sender bonus");
            require(kro.generateTokens(_referrer, bonusAmount), "Failed minting referrer bonus");
        }

         
        DetailedERC20 dai = DetailedERC20(DAI_ADDR);
        require(dai.transfer(beneficiary, _donationInDAI), "Failed DAI transfer to beneficiary");
        
         
        emit Register(msg.sender, block.number, _donationInDAI);
    }


     

    function proxyPayment(address _owner) public payable returns(bool) {
        return false;
    }


    function onTransfer(address _from, address _to, uint _amount) public returns(bool) {
        return false;
    }


    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool) {
        return false;
    }


     

    function registerWithDAI(uint256 _donationInDAI, address _referrer) public nonReentrant {
        DetailedERC20 dai = DetailedERC20(DAI_ADDR);
        require(dai.transferFrom(msg.sender, this, _donationInDAI), "Failed DAI transfer to IAO");
        _register(_donationInDAI, _referrer);
    }


    function registerWithETH(address _referrer) public payable nonReentrant {
        DetailedERC20 dai = DetailedERC20(DAI_ADDR);
        KyberNetworkProxyInterface kyber = KyberNetworkProxyInterface(KYBER_ADDR);
        uint256 daiRate;
        bytes memory hint;

         
        (,daiRate) = kyber.getExpectedRate(ETH_TOKEN_ADDRESS, dai, msg.value);
        require(daiRate > 0, "Zero price");
        uint256 receivedDAI = kyber.tradeWithHint.value(msg.value)(ETH_TOKEN_ADDRESS, msg.value, dai, this, MAX_DONATION * 2, daiRate, 0, hint);
        
         
        if (receivedDAI > MAX_DONATION) {
            require(dai.transfer(msg.sender, receivedDAI.sub(MAX_DONATION)), "Excess DAI transfer failed");
            receivedDAI = MAX_DONATION;
        }

         
        _register(receivedDAI, _referrer);
    }

     
    function registerWithToken(address _token, uint256 _donationInTokens, address _referrer) public nonReentrant {
        require(_token != address(0) && _token != address(ETH_TOKEN_ADDRESS) && _token != DAI_ADDR, "Invalid token");
        DetailedERC20 token = DetailedERC20(_token);
        require(token.totalSupply() > 0, "Zero token supply");

        DetailedERC20 dai = DetailedERC20(DAI_ADDR);
        KyberNetworkProxyInterface kyber = KyberNetworkProxyInterface(KYBER_ADDR);
        uint256 daiRate;
        bytes memory hint;

         
        require(token.transferFrom(msg.sender, this, _donationInTokens), "Failed token transfer to IAO");

         
        (,daiRate) = kyber.getExpectedRate(token, dai, _donationInTokens);
        require(daiRate > 0, "Zero price");
        require(token.approve(KYBER_ADDR, _donationInTokens.mul(PRECISION).div(10**uint256(token.decimals()))), "Token approval failed");
        uint256 receivedDAI = kyber.tradeWithHint(token, _donationInTokens, dai, this, MAX_DONATION * 2, daiRate, 0, hint);

         
        if (receivedDAI > MAX_DONATION) {
            require(dai.transfer(msg.sender, receivedDAI.sub(MAX_DONATION)), "Excess DAI transfer failed");
            receivedDAI = MAX_DONATION;
        }

         
        _register(receivedDAI, _referrer);
    }


    function () public payable nonReentrant {
        registerWithETH(address(0));
    }
}