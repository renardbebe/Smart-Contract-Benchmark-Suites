 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract ERC20{

bool public isERC20 = true;

function balanceOf(address who) constant returns (uint256);

function transfer(address _to, uint256 _value) returns (bool);

function transferFrom(address _from, address _to, uint256 _value) returns (bool);

function approve(address _spender, uint256 _value) returns (bool);

function allowance(address _owner, address _spender) constant returns (uint256);

}



contract Candy is Pausable {
  ERC20 public erc20;
   

  function Candy(address _address){
        ERC20 candidateContract = ERC20(_address);
        require(candidateContract.isERC20());
        erc20 = candidateContract;
  }	
  
  function() external payable {
        require(
            msg.sender != address(0)
        );
      erc20.transfer(msg.sender,uint256(5000000000000000000)); 
       
       
  }
  
  function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
  }
}