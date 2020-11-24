 

pragma solidity ^0.4.24;

 
 
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
contract Evabot {
    function increasePendingTokenBalance(address _user, uint256 _amount) public;
}

 
contract EvotExchange {
    function increaseEthBalance(address _user, uint256 _amount) public;
    function increaseTokenBalance(address _user, uint256 _amount) public;
}

 
contract Evoai {
  
  using SafeMath for uint256;
  address private admin;  
  address private evabot_contract;  
  address private exchange_contract;  
  address private tokenEVOT;  
  uint256 public feeETH;  
  uint256 public feeEVOT;  
  uint256 public totalEthFee;  
  uint256 public totalTokenFee;  
  mapping (address => uint256) public tokenBalance;  
  mapping (address => uint256) public etherBalance;  
  
   
  event Deposit(uint256 types, address user, uint256 amount);  
  event Withdraw(uint256 types, address user, uint256 amount);  
  event Transfered(uint256 types, address _from, uint256 amount, address _to); 
  
   
  constructor() public {
    admin = msg.sender;
    totalEthFee = 0;  
    totalTokenFee = 0;  
  }

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }
  
   
  function setTokenAddress(address _token) onlyAdmin() public {
      tokenEVOT = _token;
  }
  
   
  function setEvabotContractAddress(address _token) onlyAdmin() public {
      evabot_contract = _token;
  }
  
   
  function setExchangeContractAddress(address _token) onlyAdmin() public {
      exchange_contract = _token;
  }
  
   
  function setETHFee(uint256 amount) onlyAdmin() public {
    feeETH = amount;
  }
  
   
  function setTokenFee(uint256 amount) onlyAdmin() public {
    feeEVOT = amount;
  }
  
   
  function changeAdmin(address admin_) onlyAdmin() public {
    admin = admin_;
  }

   
  function deposit() payable public {
    totalEthFee = totalEthFee.add(feeETH);
    etherBalance[msg.sender] = (etherBalance[msg.sender]).add(msg.value.sub(feeETH));
    emit Deposit(0, msg.sender, msg.value);  
  }

  function() payable public {
      
  }
  
   
  function withdraw(uint256 amount) public {
    require(etherBalance[msg.sender] >= amount);
    etherBalance[msg.sender] = etherBalance[msg.sender].sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(0, msg.sender, amount);  
  }

   
  function depositToken(uint256 amount) public {
     
    if (!ERC20(tokenEVOT).transferFrom(msg.sender, this, amount)) revert();
    totalTokenFee = totalTokenFee.add(feeEVOT);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].add(amount.sub(feeEVOT));
    emit Deposit(1, msg.sender, amount);  
  }

   
  function withdrawToken(uint256 amount) public {
    require(tokenBalance[msg.sender] >= amount);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(amount);
    if (!ERC20(tokenEVOT).transfer(msg.sender, amount)) revert();
    emit Withdraw(1, msg.sender, amount);  
  }

   
  function transferETH(uint256 amount) public {
    require(etherBalance[msg.sender] >= amount);
    etherBalance[msg.sender] = etherBalance[msg.sender].sub(amount);
    exchange_contract.transfer(amount);
    EvotExchange(exchange_contract).increaseEthBalance(msg.sender, amount);
    emit Transfered(0, msg.sender, amount, msg.sender);
  }

   
  function transferToken(address _receiver, uint256 amount) public {
    if (tokenEVOT==0) revert();
    require(tokenBalance[msg.sender] >= amount);
    tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(amount);
    if (!ERC20(tokenEVOT).transfer(_receiver, amount)) revert();
    if (_receiver == evabot_contract)
        Evabot(evabot_contract).increasePendingTokenBalance(msg.sender, amount);
    if (_receiver == exchange_contract)
        EvotExchange(exchange_contract).increaseTokenBalance(msg.sender, amount);
    emit Transfered(1, msg.sender, amount, msg.sender);
  }
  
   
  function recevedEthFromEvabot(address _user, uint256 _amount) public {
    require(msg.sender == evabot_contract);
    etherBalance[_user] = etherBalance[_user].add(_amount);
  }
  
   
  function recevedTokenFromEvabot(address _user, uint256 _amount) public {
    require(msg.sender == evabot_contract);
    tokenBalance[_user] = tokenBalance[_user].add(_amount);
  }
  
   
  function recevedEthFromExchange(address _user, uint256 _amount) public {
    require(msg.sender == exchange_contract);
    etherBalance[_user] = etherBalance[_user].add(_amount);
  }
  
   
  function feeWithdrawEthAmount(uint256 amount) onlyAdmin() public {
    require(totalEthFee >= amount);
    totalEthFee = totalEthFee.sub(amount);
    msg.sender.transfer(amount);
  }

   
  function feeWithdrawEthAll() onlyAdmin() public {
    if (totalEthFee == 0) revert();
    totalEthFee = 0;
    msg.sender.transfer(totalEthFee);
  }

   
  function feeWithdrawTokenAmount(uint256 amount) onlyAdmin() public {
    require(totalTokenFee >= amount);
    if (!ERC20(tokenEVOT).transfer(msg.sender, amount)) revert();
    totalTokenFee = totalTokenFee.sub(amount);
  }

   
  function feeWithdrawTokenAll() onlyAdmin() public {
    if (totalTokenFee == 0) revert();
    if (!ERC20(tokenEVOT).transfer(msg.sender, totalTokenFee)) revert();
    totalTokenFee = 0;
  }
  
   
  function withrawAllEthOnContract() onlyAdmin() public {
    msg.sender.transfer(address(this).balance);
  }
  
   
  function withdrawAllTokensOnContract(uint256 _balance) onlyAdmin() public {
    if (!ERC20(tokenEVOT).transfer(msg.sender, _balance)) revert();
  }

   
  function getEvotTokenAddress() public constant returns (address) {
    return tokenEVOT;    
  }
  
   
  function getEvabotContractAddress() public constant returns (address) {
    return evabot_contract;
  }
  
   
  function getExchangeContractAddress() public constant returns (address) {
    return exchange_contract;
  }
  
   
  function balanceOfToken(address user) public constant returns (uint256) {
    return tokenBalance[user];
  }

   
  function balanceOfETH(address user) public constant returns (uint256) {
    return etherBalance[user];
  }

   
  function balanceOfContractFeeEth() public constant returns (uint256) {
    return totalEthFee;
  }

   
  function balanceOfContractFeeToken() public constant returns (uint256) {
    return totalTokenFee;
  }
  
   
  function getCurrentEthFee() public constant returns (uint256) {
      return feeETH;
  }
  
   
  function getCurrentTokenFee() public constant returns (uint256) {
      return feeEVOT;
  }
}