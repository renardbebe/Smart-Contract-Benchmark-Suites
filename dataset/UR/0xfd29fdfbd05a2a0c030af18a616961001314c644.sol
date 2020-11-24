 

pragma solidity ^0.5.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
contract Multisend {
  using SafeMath for uint256;

  address payable private _owner;  
  mapping(address => bool) public whitelist;  
  uint private _fee;  
  mapping(address => mapping(address => uint256)) public balances;  


   
  constructor(uint256 initialFee) public {
    _owner = msg.sender;
    _fee = initialFee;
  }

   
  function deposit(address[] memory tokenDepositAddress, uint256[] memory tokenDepositAmount) public payable {
    require(tokenDepositAddress.length == tokenDepositAmount.length);
     
    if(msg.value != 0) {
      uint256 etherFee = msg.value.div(10000).mul(_fee);  
      balances[msg.sender][address(0)] = balances[msg.sender][address(0)].add(msg.value.sub(etherFee));
      balances[address(this)][address(0)] = balances[address(this)][address(0)].add(etherFee);
    }
    for (uint i=0;i<tokenDepositAddress.length;i++) {
      require(whitelist[tokenDepositAddress[i]] == true, "token not whitelisted");
      uint256 tokenFee = tokenDepositAmount[i].div(10000).mul(_fee);
      IERC20(tokenDepositAddress[i]).transferFrom(msg.sender, address(this), tokenDepositAmount[i]);
      balances[msg.sender][tokenDepositAddress[i]] = balances[msg.sender][tokenDepositAddress[i]].add(tokenDepositAmount[i].sub(tokenFee));
      balances[address(this)][tokenDepositAddress[i]] = balances[address(this)][tokenDepositAddress[i]].add(tokenFee);
    }
  }

   
  function sendPayment(address[] memory tokens, address payable[] memory recipients, uint256[] memory amounts) public payable returns (bool) {
    require(tokens.length == recipients.length);
    require(tokens.length == amounts.length);
    uint256 total_ether_amount = 0;
    for (uint i=0; i < recipients.length; i++) {
      if(tokens[i] != address(0)) {
        balances[msg.sender][tokens[i]] = balances[msg.sender][tokens[i]].sub(amounts[i]);
        IERC20(tokens[i]).transfer(recipients[i], amounts[i]);
      }
      else {
        total_ether_amount = total_ether_amount.add(amounts[i]);
        balances[msg.sender][address(0)] = balances[msg.sender][address(0)].sub(amounts[i]);
        recipients[i].transfer(amounts[i]);
      }
    }
  }

   
  function depositAndSendPayment(address[] calldata tokenDepositAddress, uint256[] calldata tokenDepositAmount, address[] calldata tokens, address payable[] calldata recipients, uint256[] calldata amounts) external payable returns (bool) {
      deposit(tokenDepositAddress, tokenDepositAmount);
      sendPayment(tokens, recipients, amounts);
  }

   
  function withdrawTokens(address payable[] calldata tokenAddresses) external {
    for(uint i=0; i<tokenAddresses.length;i++) {
      uint balance = balances[msg.sender][tokenAddresses[i]];
      balances[msg.sender][tokenAddresses[i]] = 0;
      IERC20 ERC20 = IERC20(tokenAddresses[i]);
      ERC20.transfer(msg.sender, balance);
    }
  }

   
  function withdrawEther() external {
    uint balance = balances[msg.sender][address(0)];
    balances[msg.sender][address(0)] = 0;
    msg.sender.transfer(balance);
  }

   

   
  function getBalance(address owner, address token) external view returns (uint256) {
    return balances[owner][token];
  }

   
  function owner() external view returns (address) {
    return _owner;
  }

   

   
  function ownerWithdrawTokens(address payable[] calldata tokenAddresses) external onlyOwner {
    for(uint i=0; i<tokenAddresses.length;i++) {
      uint balance = balances[address(this)][tokenAddresses[i]];
      balances[address(this)][tokenAddresses[i]] = 0;
      IERC20 ERC20 = IERC20(tokenAddresses[i]);
      ERC20.transfer(_owner, balance);
    }
  }

   
  function ownerWithdrawEther() external onlyOwner {
    uint balance = balances[address(this)][address(0)];
    balances[address(this)][address(0)] = 0;
    _owner.transfer(balance);
  }

   
  function whitelistAddress(address contractAddress) external onlyOwner {
    whitelist[contractAddress] = true;
  }

   
  function transferOwnership(address payable newOwner) external onlyOwner {
    require(newOwner != address(0), "Owner address may not be set to zero address");
    _owner = newOwner;
  }

  modifier onlyOwner {
    require(msg.sender == _owner, "Sender is not owner of the contract");
    _;
  }
}