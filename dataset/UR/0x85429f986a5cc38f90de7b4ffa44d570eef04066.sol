 

pragma solidity ^0.4.23;

 
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

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract ERC223 is ERC20 {
  function transfer(address to, uint value, bytes data) returns (bool ok);
  function transferFrom(address from, address to, uint value, bytes data) returns (bool ok);
}



 

contract ERC223Receiver {
  function tokenFallback(address _sender, address _origin, uint _value, bytes _data) returns (bool ok);
}







 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

   
}


 
contract StandardToken is ERC20, SafeMath {
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  function transfer(address _to, uint _value) returns (bool success) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];
     
     
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract KinguinKrowns is ERC223, StandardToken {
  address public owner;   
  string public constant name = "PINGUINS";
  string public constant symbol = "PGS";
  uint8 public constant decimals = 18;
   
		
  function KinguinKrowns() {
	owner = msg.sender;
    totalSupply = 100000000 * (10**18);  
    balances[msg.sender] = totalSupply;
  } 
  
   
  
   
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
     
    if (!super.transfer(_to, _value)) throw;  
    if (isContract(_to)) return contractFallback(msg.sender, _to, _value, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value, bytes _data) returns (bool success) {
    if (!super.transferFrom(_from, _to, _value)) throw;  
    if (isContract(_to)) return contractFallback(_from, _to, _value, _data);
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    return transfer(_to, _value, new bytes(0));
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    return transferFrom(_from, _to, _value, new bytes(0));
  }

   
  function contractFallback(address _origin, address _to, uint _value, bytes _data) private returns (bool success) {
    ERC223Receiver receiver = ERC223Receiver(_to);
    return receiver.tokenFallback(msg.sender, _origin, _value, _data);
  }

   
  function isContract(address _addr) private returns (bool is_contract) {
     
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
  }
  
   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
	
}

contract KinguinIco is SafeMath, ERC223Receiver {
  address constant public superOwner = 0xcEbb7454429830C92606836350569A17207dA857;
  address public owner;              
  address public api;                
  KinguinKrowns public krs;      
  
   
  struct IcoRoundData {
    uint rMinEthPayment;             
    uint rKrsUsdFixed;               
    uint rKycTreshold;               
    uint rMinKrsCap;                 
    uint rMaxKrsCap;                 
    uint rStartBlock;                
    uint rEndBlock;                  
    uint rEthPaymentsAmount;         
    uint rEthPaymentsCount;          
    uint rSentKrownsAmount;          
    uint rSentKrownsCount;           
    bool roundCompleted;             
  }
  mapping(uint => IcoRoundData) public icoRounds;   
  
  mapping(address => bool) public allowedAdresses;  
  
  struct RoundPayments {             
    uint round;
    uint amount;
  }
   
   
  mapping(address => RoundPayments) public paymentsFromAddress; 

  uint public ethEur;                
  uint public ethUsd;                
  uint public krsUsd;                
  uint public rNo;                   
  bool public icoInProgress;         
  bool public apiAccessDisabled;     
  
  event LogReceivedEth(address from, uint value, uint block);  
  event LogSentKrs(address to, uint value, uint block);  

   
  modifier onlySuperOwner() {
	require(msg.sender == superOwner);
    _;
  }

   
  modifier onlyOwner() {
	require(msg.sender == owner);
    _;
  }
  
   
  modifier onlyOwnerOrApi() {
	require(msg.sender == owner || msg.sender == api);
    if (msg.sender == api && api != owner) {
      require(!apiAccessDisabled);
	}
    _;
  }
 
  function KinguinIco() {
    owner = msg.sender;  
    api = msg.sender;  
    krs = KinguinKrowns(0xdfb410994b66778bd6cc2c82e8ffe4f7b2870006);  
  } 
 
   
  function () payable {
    if(msg.sender != owner) {  
      if(block.number >= icoRounds[rNo].rStartBlock && block.number <= icoRounds[rNo].rEndBlock && !icoInProgress) {
        icoInProgress = true;
      }  
      require(block.number >= icoRounds[rNo].rStartBlock && block.number <= icoRounds[rNo].rEndBlock && !icoRounds[rNo].roundCompleted);  
      require(msg.value >= icoRounds[rNo].rMinEthPayment);  
	  require(ethEur > 0);  
	  require(ethUsd > 0);  
	  uint krowns4eth;
	  if(icoRounds[rNo].rKrsUsdFixed > 0) {  
        krowns4eth = safeDiv(safeMul(safeMul(msg.value, ethUsd), uint(100)), icoRounds[rNo].rKrsUsdFixed);
	  } else {  
		require(krsUsd > 0);  
        krowns4eth = safeDiv(safeMul(safeMul(msg.value, ethUsd), uint(100)), krsUsd);
  	  }
      require(safeAdd(icoRounds[rNo].rSentKrownsAmount, krowns4eth) <= icoRounds[rNo].rMaxKrsCap);  

      if(paymentsFromAddress[msg.sender].round != rNo) {  
        paymentsFromAddress[msg.sender].round = rNo;  
        paymentsFromAddress[msg.sender].amount = 0;  
      }   
      if(safeMul(ethEur, safeDiv(msg.value, 10**18)) >= icoRounds[rNo].rKycTreshold ||  
         
        safeMul(ethEur, safeDiv(safeAdd(paymentsFromAddress[msg.sender].amount, msg.value), 10**18)) >= icoRounds[rNo].rKycTreshold) { 
		require(allowedAdresses[msg.sender]);  
      }

      icoRounds[rNo].rEthPaymentsAmount = safeAdd(icoRounds[rNo].rEthPaymentsAmount, msg.value);
      icoRounds[rNo].rEthPaymentsCount += 1; 
      paymentsFromAddress[msg.sender].amount = safeAdd(paymentsFromAddress[msg.sender].amount, msg.value);
      LogReceivedEth(msg.sender, msg.value, block.number);
      icoRounds[rNo].rSentKrownsAmount = safeAdd(icoRounds[rNo].rSentKrownsAmount, krowns4eth);
      icoRounds[rNo].rSentKrownsCount += 1;
      krs.transfer(msg.sender, krowns4eth);
      LogSentKrs(msg.sender, krowns4eth, block.number);
    } else {  
	    if(block.number >= icoRounds[rNo].rStartBlock && block.number <= icoRounds[rNo].rEndBlock && !icoInProgress) {
          icoInProgress = true;
        }
        if(block.number > icoRounds[rNo].rEndBlock && icoInProgress) {
          endIcoRound();
        }
    }
  }

   
  
   
  Tkn tkn;

  struct Tkn {
    address addr;
    address sender;
    address origin;
    uint256 value;
    bytes data;
    bytes4 sig;
  }

  function tokenFallback(address _sender, address _origin, uint _value, bytes _data) returns (bool ok) {
    if (!supportsToken(msg.sender)) return false;
    return true;
  }

  function getSig(bytes _data) private returns (bytes4 sig) {
    uint l = _data.length < 4 ? _data.length : 4;
    for (uint i = 0; i < l; i++) {
      sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (l - 1 - i))));
    }
  }

  bool __isTokenFallback;

  modifier tokenPayable {
    if (!__isTokenFallback) throw;
    _;
  }
  
  function supportsToken(address token) returns (bool) {
    if (token == address(krs)) {
	  return true; 
    } else {
      revert();
	}
  }
   


   
  function newIcoRound(uint _rMinEthPayment, uint _rKrsUsdFixed, uint _rKycTreshold,
    uint _rMinKrsCap, uint _rMaxKrsCap, uint _rStartBlock, uint _rEndBlock) public onlyOwner {
    require(!icoInProgress);             
    require(rNo < 25);                   
	rNo += 1;                            
	icoRounds[rNo] = IcoRoundData(_rMinEthPayment, _rKrsUsdFixed, _rKycTreshold, _rMinKrsCap, _rMaxKrsCap, 
	  _rStartBlock, _rEndBlock, 0, 0, 0, 0, false);  
  }
  
   
  function removeCurrentIcoRound() public onlyOwner {
    require(icoRounds[rNo].rEthPaymentsAmount == 0);  
	require(!icoRounds[rNo].roundCompleted);  
    icoInProgress = false;
    icoRounds[rNo].rMinEthPayment = 0;
    icoRounds[rNo].rKrsUsdFixed = 0;
    icoRounds[rNo].rKycTreshold = 0;
    icoRounds[rNo].rMinKrsCap = 0;
    icoRounds[rNo].rMaxKrsCap = 0;
    icoRounds[rNo].rStartBlock = 0;
    icoRounds[rNo].rEndBlock = 0;
    icoRounds[rNo].rEthPaymentsAmount = 0;
    icoRounds[rNo].rEthPaymentsCount = 0;
    icoRounds[rNo].rSentKrownsAmount = 0;
    icoRounds[rNo].rSentKrownsCount = 0;
    if(rNo > 0) rNo -= 1;
  }

  function changeIcoRoundEnding(uint _rEndBlock) public onlyOwner {
    require(icoRounds[rNo].rStartBlock > 0);  
    icoRounds[rNo].rEndBlock = _rEndBlock;  
  }
 
   
  function endIcoRound() private {
    icoInProgress = false;
	icoRounds[rNo].rEndBlock = block.number;
	icoRounds[rNo].roundCompleted = true;
  }

   
  function endIcoRoundManually() public onlyOwner {
    endIcoRound();
  }
  
   
  function addAllowedAddress(address _address) public onlyOwnerOrApi {
    allowedAdresses[_address] = true;
  }
  function removeAllowedAddress(address _address) public onlyOwnerOrApi {
    delete allowedAdresses[_address];
  }

   
   
  function setEthEurRate(uint _ethEur) public onlyOwnerOrApi {
    ethEur = _ethEur;
  }

   
  function setEthUsdRate(uint _ethUsd) public onlyOwnerOrApi {
    ethUsd = _ethUsd;
  }

   
  function setKrsUsdRate(uint _krsUsd) public onlyOwnerOrApi {
    krsUsd = _krsUsd;
  }
  
   
  function setAllRates(uint _ethEur, uint _ethUsd, uint _krsUsd) public onlyOwnerOrApi {
    ethEur = _ethEur;
    ethUsd = _ethUsd;
	  krsUsd = _krsUsd;
  }
  
   
  function sendKrs(address _receiver, uint _amount) public onlyOwnerOrApi {
    krs.transfer(_receiver, _amount);
  }

   
  function getKrsFromApproved(address _from, uint _amount) public onlyOwnerOrApi {
    krs.transferFrom(_from, address(this), _amount);
  }
  
   
  function sendEth(address _receiver, uint _amount) public onlyOwner {
    _receiver.transfer(_amount);
  }
 
   
  function disableApiAccess(bool _disabled) public onlyOwner {
    apiAccessDisabled = _disabled;
  }
  
   
  function changeApi(address _address) public onlyOwner {
    api = _address;
  }

   
  function changeOwner(address _address) public onlySuperOwner {
    owner = _address;
  }
  
}

library MicroWalletLib {

     
    KinguinKrowns constant token = KinguinKrowns(0xdfb410994b66778bd6cc2c82e8ffe4f7b2870006);

    struct MicroWalletStorage {
        uint krsAmount ;
        address owner;
    }

    function toBytes(address a) private pure returns (bytes b){
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function processPayment(MicroWalletStorage storage self, address _sender) public {
        require(msg.sender == address(token));

        if (self.owner == _sender) {     
            self.krsAmount = 0;
            return;
        }

        require(self.krsAmount > 0);
        
        uint256 currentBalance = token.balanceOf(address(this));

        require(currentBalance >= self.krsAmount);

        if(currentBalance > self.krsAmount) {
             
            require(token.transfer(_sender, currentBalance - self.krsAmount));
        }

        require(token.transfer(self.owner, self.krsAmount, toBytes(_sender)));

        self.krsAmount = 0;
    }
}

contract KinguinVault is Ownable, ERC223Receiver {
    
    mapping(uint=>address) public microWalletPayments;
    mapping(uint=>address) public microWalletsAddrs;
    mapping(address=>uint) public microWalletsIDs;
    mapping(uint=>uint) public microWalletPaymentBlockNr;

    KinguinKrowns public token;
    uint public uncleSafeNr = 5;
    address public withdrawAddress;

    modifier onlyWithdraw() {
        require(withdrawAddress == msg.sender);
        _;
    }

    constructor(KinguinKrowns _token) public {
        token = _token;
        withdrawAddress = owner;
    }
    
    function createMicroWallet(uint productOrderID, uint krsAmount) onlyOwner public {
        require(productOrderID != 0 && microWalletsAddrs[productOrderID] == address(0x0));
        microWalletsAddrs[productOrderID] = new MicroWallet(krsAmount);
        microWalletsIDs[microWalletsAddrs[productOrderID]] = productOrderID;
    }

    function getMicroWalletAddress(uint productOrderID) public view returns(address) {
        return microWalletsAddrs[productOrderID];
    }

    function closeMicroWallet(uint productOrderID) onlyOwner public {
        token.transfer(microWalletsAddrs[productOrderID], 0);
    }

    function checkIfOnUncle(uint currentBlockNr, uint transBlockNr) private view returns (bool) {
        if((currentBlockNr - transBlockNr) < uncleSafeNr) {
            return true;
        }
        return false;
    }

    function setUncleSafeNr(uint newUncleSafeNr) onlyOwner public {
        uncleSafeNr = newUncleSafeNr;
    }

    function getProductOrderPayer(uint productOrderID) public view returns (address) {
        if (checkIfOnUncle(block.number, microWalletPaymentBlockNr[productOrderID])) {
            return 0;    
        }
        return microWalletPayments[productOrderID];
    }

    function tokenFallback(address _sender, address _origin, uint _value, bytes _data) public returns (bool)  {
        require(msg.sender == address(token));
        if(microWalletsIDs[_sender] > 0) {
            microWalletPayments[microWalletsIDs[_sender]] = bytesToAddr(_data);
            microWalletPaymentBlockNr[microWalletsIDs[_sender]] = block.number;
        }
        return true;
    }

    function setWithdrawAccount(address _addr) onlyWithdraw public {
        withdrawAddress = _addr;
    } 

    function withdrawKrowns(address wallet, uint amount) onlyWithdraw public {
        require(wallet != address(0x0));
        token.transfer(wallet, amount);
    }

    function bytesToAddr (bytes b) private pure returns (address) {
        uint result = 0;
        for (uint i = b.length-1; i+1 > 0; i--) {
            uint c = uint(b[i]);
            uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
            result += to_inc;
        }
        return address(result);
    }
}

contract MicroWallet is ERC223Receiver {
    
    MicroWalletLib.MicroWalletStorage private mwStorage;

    constructor(uint _krsAmount) public {
        mwStorage.krsAmount = _krsAmount;
        mwStorage.owner = msg.sender;
    }

    function tokenFallback(address _sender, address _origin, uint _value, bytes _data) public returns (bool)  {
        MicroWalletLib.processPayment(mwStorage, _sender);
        
        return true;
    }
}