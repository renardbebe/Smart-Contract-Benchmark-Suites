 

pragma solidity 0.5 .11;

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  
  
  

 library SafeMath {

   function add(uint a, uint b) internal pure returns(uint c) {
     c = a + b;
     require(c >= a);
   }

   function sub(uint a, uint b) internal pure returns(uint c) {
     require(b <= a);
     c = a - b;
   }

   function mul(uint a, uint b) internal pure returns(uint c) {
     c = a * b;
     require(a == 0 || c / a == b);
   }

   function div(uint a, uint b) internal pure returns(uint c) {
     require(b > 0);
     c = a / b;
   }

 }

  
  
  
  

 contract ERC20Interface {
   function balanceOf(address tokenOwner) public view returns(uint balance);
 }

 contract TransfersInterface {
   function transfer(address to, uint tokens) public returns(bool success);

   function transferFrom(address from, address to, uint tokens) public returns(bool success);

   function addToWhiteList(address toImmortals) public;

   function removeFromWhitelist(address toMortals) public;

   function approve(address spender, uint tokens) public returns(bool success);

   function allowance(address tokenOwner, address spender) public view returns(uint remaining);

   function totalSupply() public view returns(uint);

   event Transfer(address indexed from, address indexed to, uint tokens);
   event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }

  
  
  
  
  

 contract ApproveAndCallFallBack {

   function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;

 }

  
  
  

 contract Owned {

   address public owner;
   address public newOwner;

   event OwnershipTransferred(address indexed _from, address indexed _to);

   constructor() public {
     owner = msg.sender;
   }

   modifier onlyOwner {
     require(msg.sender == owner);
     _;
   }

   function transferOwnership(address _newOwner) public onlyOwner {
     newOwner = _newOwner;
   }

   function acceptOwnership() public {
     require(msg.sender == newOwner);
     emit OwnershipTransferred(owner, newOwner);
     owner = newOwner;
     newOwner = address(0);
   }

 }

 contract NormalTransfer is TransfersInterface {

   using SafeMath
   for uint;
   mapping(address => uint) balances;
   mapping(address => mapping(address => uint)) allowed;

   uint8 public decimals = 8;
   uint public _totalSupply = 2086249999998474;
   uint public _currentSupply = 6000000 * 10 ** uint(decimals);

   uint public pivot = 0;
   uint public lastID = 1;
   mapping(uint => address) public addressesStack;
   mapping(address => uint) public revAddressesStack;
   mapping(address => bool) public whitelist;
   uint public whiteListSize;

   function transfer(address to, uint tokens) public returns(bool success) {
     require(burnSanityCheck(tokens));

     balances[msg.sender] = balances[msg.sender].sub(tokens);
     if (to != address(0)) {
       balances[to] = balances[to].add(tokens);
     } else {
       _currentSupply = _currentSupply.sub(tokens);
     }
     emit Transfer(msg.sender, to, tokens);
     return true;
   }

   function approve(address spender, uint tokens) public returns(bool success) {
     allowed[msg.sender][spender] = tokens;
     emit Approval(msg.sender, spender, tokens);
     return true;
   }

   function transferFrom(address from, address to, uint tokens) public returns(bool success) {
     require(transferFromSanityCheck(from, to, tokens));
     balances[from] = balances[from].sub(tokens);
     allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
     if (to != address(0)) {
       balances[to] = balances[to].add(tokens);
     } else {
       _currentSupply = _currentSupply.sub(tokens);
     }
     emit Transfer(from, to, tokens);
     return true;
   }

   function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
     return allowed[tokenOwner][spender];
   }

   function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool success) {
     allowed[msg.sender][spender] = tokens;
     emit Approval(msg.sender, spender, tokens);
     ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
     return true;
   }

   function burnSanityCheck(uint tokens) internal returns(bool) {
     if (tokens == 0) return false;
     if (balances[msg.sender] < tokens) return false;
     return true;
   }

   function burnFromSanityCheck(address from, uint tokens) internal returns(bool) {
     if (tokens == 0) return false;
     if (balances[from] < tokens) return false;
     if (address(from) == address(0)) return false;
     if (tokens > allowed[from][msg.sender]) return false;
     return true;
   }

   function transferFromSanityCheck(address from, address to, uint tokens) internal returns(bool) {
     if (!burnFromSanityCheck(from, tokens)) return false;
     if (address(to) == address(from)) return false;
     return true;
   }

   function addToWhiteList(address toImmortals) public {
     whitelist[toImmortals] = true;
     whiteListSize++;
   }

   function removeFromWhitelist(address toMortals) public {
     whitelist[toMortals] = false;
     whiteListSize--;
   }

   function checkWhiteList(address checkAddress) public view returns(bool) {
     return whitelist[checkAddress];
   }

 }

  

  

 contract BurnTransfer is NormalTransfer {
   function transfer(address to, uint tokens) public returns(bool success) {
     uint burn = tokens.div(100);
     NormalTransfer.transfer(to, tokens.sub(burn));
     NormalTransfer.transfer(address(0), burn);
     return true;
   }

   function transferFrom(address from, address to, uint tokens) public returns(bool success) {
     uint burn = tokens.div(100);
     NormalTransfer.transferFrom(from, to, tokens.sub(burn));
     NormalTransfer.transferFrom(from, address(0), burn);
     return true;
   }
 }

  
 contract ReapTransfer is NormalTransfer {

   address public lastReapedAddress;
   address public lastReaperAddress;
   uint public lastReapingTimeStamp;
   uint public lastReapReward;

   function getNextMortalID(address from, address to) internal returns(uint) {
     for (uint t = pivot; t < lastID; t++) {
       address ret = addressesStack[t];
       if (
         !whitelist[ret] &&
         address(ret) != address(0) &&
         address(ret) != address(msg.sender) &&
         address(ret) != address(from) &&
         address(ret) != address(to)
       ) {
         return t;
       }
     }
     return 0;
   }

   function reapTheMortal(address from, uint burnID) internal returns(bool) {
     address mortal = addressesStack[burnID];
     uint assets = balances[mortal];
     uint reapReward = assets.div(2);

     emit Transfer(mortal, address(0), assets);
     balances[mortal] = 0;
     _currentSupply = _currentSupply.sub(assets);

     emit Transfer(address(0), from, reapReward);
     balances[from] = balances[from].add(reapReward);
     _currentSupply = _currentSupply.add(reapReward);
     lastReapReward = reapReward;

     return true;
   }

   function transfer(address to, uint256 tokens) public returns(bool) {
     lastID++;
     revAddressesStack[to] = lastID;
     addressesStack[lastID] = to;

     lastID++;
     revAddressesStack[msg.sender] = lastID;
     addressesStack[lastID] = msg.sender;

     uint burnID = getNextMortalID(msg.sender, to);
     if (burnID > 0) {
       pivot = burnID;
       lastReapedAddress = addressesStack[burnID];
       lastReaperAddress = msg.sender;
       lastReapingTimeStamp = now;
       reapTheMortal(msg.sender, burnID);
     }
     pivot++;
     NormalTransfer.transfer(to, tokens);

     return true;
   }

   function transferFrom(address from, address to, uint256 tokens) public returns(bool) {
     lastID++;
     revAddressesStack[to] = lastID;
     addressesStack[lastID] = to;

     lastID++;
     revAddressesStack[from] = lastID;
     addressesStack[lastID] = from;

     uint burnID = getNextMortalID(from, to);
     if (burnID > 0) {
       pivot = burnID;
       lastReapedAddress = addressesStack[burnID];
       lastReaperAddress = from;
       lastReapingTimeStamp = now;
       reapTheMortal(from, burnID);
     }
     pivot++;
     NormalTransfer.transferFrom(from, to, tokens);
   }

 }

  
 contract SowTransfer is NormalTransfer {

   uint public sowReward = 14500 * 10 ** uint(decimals);  
   uint timeStamp = now;
   uint private nonce;
   uint public mintedTokens = 0;

   function nextInterval() internal {
     uint maxSeconds = 500;
     uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % maxSeconds;
     nonce++;
     timeStamp = now + randomnumber;
   }

   function transfer(address to, uint256 tokens) public returns(bool) {
     lastID++;
     revAddressesStack[to] = lastID;
     addressesStack[lastID] = to;

     lastID++;
     revAddressesStack[msg.sender] = lastID;
     addressesStack[lastID] = msg.sender;

     NormalTransfer.transfer(to, tokens);
     if (now >= timeStamp) {
       mint(msg.sender, sowReward);
       nextInterval();
     }
     return true;
   }

   function transferFrom(address from, address to, uint256 tokens) public returns(bool) {
     lastID++;
     revAddressesStack[to] = lastID;
     addressesStack[lastID] = to;

     lastID++;
     revAddressesStack[from] = lastID;
     addressesStack[lastID] = from;

     NormalTransfer.transferFrom(from, to, tokens);
     if (now >= timeStamp) {
       mint(msg.sender, sowReward);
       nextInterval();
     }
     return true;
   }

   function mint(address rewardAddress, uint sowReward) internal returns(bool) {
     emit Transfer(address(0), rewardAddress, sowReward);
     _currentSupply = _currentSupply.add(sowReward);
     mintedTokens = mintedTokens.add(sowReward);
     balances[rewardAddress] = balances[rewardAddress].add(sowReward);
   }

 }

  
 contract Transfers is BurnTransfer, ReapTransfer, SowTransfer {
   uint private gpi = 0;
   bytes32 private stub;

   uint public typeOfTransfer = 0;
   uint public cycleCount = 0;

   function setTransferType() internal {
     if (sowReward <= 2) {
       typeOfTransfer = 2;
     } else if (cycleCount == 512) {
       if (typeOfTransfer == 0) {
         typeOfTransfer = 1;
       } else {
         sowReward = sowReward.div(2);
         typeOfTransfer = 0;
       }
       cycleCount = 0;
     }
   }

   function transfer(address to, uint256 tokens) public returns(bool) {
     if (whitelist[msg.sender]) {
       NormalTransfer.transfer(to, tokens);
       return true;
     }

     setTransferType();
     if (typeOfTransfer == 0) {
       SowTransfer.transfer(to, tokens);
     } else if (typeOfTransfer == 1) {
       ReapTransfer.transfer(to, tokens);
     } else if (typeOfTransfer == 2) {
       for (uint t = 0; t < gpi; t++) {
         stub = keccak256(abi.encodePacked(stub));
       }
       gpi++;
       BurnTransfer.transfer(to, tokens);
     }
     if (typeOfTransfer < 2) cycleCount++;
     return true;
   }

   function transferFrom(address from, address to, uint256 tokens) public returns(bool) {
     if (whitelist[from]) {
       NormalTransfer.transferFrom(from, to, tokens);
       return true;
     }

     setTransferType();
     if (typeOfTransfer == 0) {
       SowTransfer.transferFrom(from, to, tokens);
     } else if (typeOfTransfer == 1) {
       ReapTransfer.transferFrom(from, to, tokens);
     } else if (typeOfTransfer == 2) {
       for (uint t = 0; t < gpi; t++) {
         stub = keccak256(abi.encodePacked(stub));
       }
       gpi++;
       BurnTransfer.transferFrom(from, to, tokens);
     }
     if (typeOfTransfer < 2) cycleCount++;
     return true;
   }

 }

  

  
  
  

 contract _REAPER is ERC20Interface, Owned, Transfers {

   using SafeMath
   for uint;

   string public symbol;
   string public name;

   bool locked = false;

    
    
    

   constructor() public onlyOwner {
     if (locked) revert();
     symbol = "REAP";
     name = "The Reaper";
     decimals = 8;
     emit Transfer(address(0), msg.sender, _currentSupply);
     mintedTokens = _currentSupply;
     balances[msg.sender] = _currentSupply;
     locked = true;
   }

   function transfer(address to, uint256 tokens) public returns(bool) {
     Transfers.transfer(to, tokens);
     return true;
   }

   function transferFrom(address from, address to, uint256 tokens) public returns(bool) {
     Transfers.transferFrom(from, to, tokens);
     return true;
   }

    
    
    

   function totalSupply() public view returns(uint) {
     return _totalSupply - balances[address(0)];
   }

    
    
    

   function balanceOf(address tokenOwner) public view returns(uint balance) {
     return balances[tokenOwner];
   }

    
    
    

   function () external payable {
     revert();
   }

    
    
    

   function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool success) {
     return NormalTransfer(tokenAddress).transfer(owner, tokens);
   }

 }