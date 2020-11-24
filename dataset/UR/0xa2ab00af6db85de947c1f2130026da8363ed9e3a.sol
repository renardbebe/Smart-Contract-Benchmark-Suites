 

pragma solidity ^0.4.3;

  
contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
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

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BlockPaperScissors is Ownable {

  using SafeMath for uint256;

    ERC20Interface bCoin;
    ERC20Interface pCoin;
    ERC20Interface sCoin;
    ERC20Interface tCoin;

    address public rpsDev = msg.sender;
    uint8 public lastMove = 1;  
    address public lastPlayer = msg.sender;
    uint public oneCoin = 1000000000000000000;

 

    function setBCoinContractAddress(address _address) external onlyOwner {
      bCoin = ERC20Interface(_address);
    }
    function setPCoinContractAddress(address _address) external onlyOwner {
      pCoin = ERC20Interface(_address);
    }
    function setSCoinContractAddress(address _address) external onlyOwner {
      sCoin = ERC20Interface(_address);
    }
    function setTCoinContractAddress(address _address) external onlyOwner {
      tCoin = ERC20Interface(_address);
    }

 

    event newMove(uint8 move);
    event newWinner(address winner);

 

    function playBps(uint8 _choice) public returns (uint8) {
      require (_choice == 1 || _choice == 2 || _choice == 3);
      if (_choice == lastMove) {
        tCoin.transfer(msg.sender, oneCoin);
        tCoin.transfer(lastPlayer, oneCoin); 
        setGame(_choice, msg.sender);
        return 3;  
      }
      if (_choice == 1) {  
        if (lastMove == 3) {
          bCoin.transfer(msg.sender, oneCoin);
          emit newWinner(msg.sender);
          setGame(_choice, msg.sender);
          return 1; 
          } else {
          pCoin.transfer(lastPlayer, oneCoin);
          emit newWinner(lastPlayer);
          setGame(_choice, msg.sender);
          return 2; 
          }
      }
      if (_choice == 2) {  
        if (lastMove == 1) {
          pCoin.transfer(msg.sender, oneCoin);
          emit newWinner(msg.sender);
          setGame(_choice, msg.sender);
          return 1; 
          } else {
          sCoin.transfer(lastPlayer, oneCoin);
          emit newWinner(lastPlayer);
          setGame(_choice, msg.sender);
          return 2; 
          }
      }
      if (_choice == 3) {  
        if (lastMove == 2) {
          sCoin.transfer(msg.sender, oneCoin);
          emit newWinner(msg.sender);
          setGame(_choice, msg.sender);
          return 1; 
          } else {
          bCoin.transfer(lastPlayer, oneCoin);
          emit newWinner(lastPlayer);
          setGame(_choice, msg.sender);
          return 2; 
          }
      }
    }

    function setGame(uint8 _move, address _player) private {
      lastMove = _move;
      lastPlayer = _player;
      emit newMove(_move);
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