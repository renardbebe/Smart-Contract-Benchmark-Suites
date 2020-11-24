 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract ChainBowPrivateSale is Pausable {

    using SafeMath for uint256;

    ERC20 public tokenContract;
    address public teamWallet;
    string public leader;
    uint256 public rate = 5000;

    uint256 public totalSupply = 0;

    event Buy(address indexed sender, address indexed recipient, uint256 value, uint256 tokens);

    mapping(address => uint256) public records;

    constructor(address _tokenContract, address _teamWallet, string _leader, uint _rate) public {
        require(_tokenContract != address(0));
        require(_teamWallet != address(0));
        tokenContract = ERC20(_tokenContract);
        teamWallet = _teamWallet;
        leader = _leader;
        rate = _rate;
    }


    function () payable public {
        buy(msg.sender);
    }

    function buy(address recipient) payable public whenNotPaused {
        require(msg.value >= 0.1 ether);

        uint256 tokens =  rate.mul(msg.value);

        tokenContract.transferFrom(teamWallet, msg.sender, tokens);

        records[recipient] = records[recipient].add(tokens);
        totalSupply = totalSupply.add(tokens);

        emit Buy(msg.sender, recipient, msg.value, tokens);

    }


     
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

     
    function changeTeamWallet(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

     
    function withdrawEth() public onlyOwner {
        teamWallet.transfer(address(this).balance);
    }


     
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ERC20Basic token = ERC20Basic(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

}