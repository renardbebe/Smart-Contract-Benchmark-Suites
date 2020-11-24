 

pragma solidity 0.4.26;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
     
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
     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
 
contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract BountyBoard {
    using SafeMath for uint256;
    
    string public bounty;
    uint256 public bountyID;
    uint256 public bountyPrice;
    address public bountyToken;
    address public bountyMaker;
    address public bountyHunter;
    address public arbiter;
    
    uint256 public arbiterFee;
    
    enum State { Blank, Posted, Claimed, Disputed }
    State public state;
    
    event bountyPosted(string indexed bounty, uint256 price, address indexed bountyToken);
    event bountyClaimed(address indexed bountyHunter);
    event bountyWithdrawn();
    event Disputed();
    event Resolved(address indexed this, address indexed bountyMaker, address indexed bountyHunter);
     
   constructor(address _bountyMaker)
        public {
                bountyMaker = _bountyMaker;
               }
                 
                  modifier onlyBountyMaker() {
                        require(msg.sender == bountyMaker);
                         _;
                        }
                 
                  modifier onlyBountyMakerOrBountyHunter() {
                        require(
                        msg.sender == bountyMaker ||
                        msg.sender == bountyHunter);
                         _;
                        }
                 
                  modifier onlyArbiter() {
                        require(msg.sender == arbiter);
                         _;
                        }
                 
                  modifier inState(State _state) {
                        require(state == _state);
                         _;
                        }
           function postBounty(string memory _bounty, uint256 _bountyPrice, address _bountyToken, address _arbiter, uint256 _arbiterFee) public onlyBountyMaker inState(State.Blank) {
                state = State.Posted;
                bounty = _bounty;
                bountyPrice = _bountyPrice;
                bountyToken = _bountyToken;
                arbiter = _arbiter;
                arbiterFee = _arbiterFee;
                bountyID = now;
                emit bountyPosted(bounty, bountyPrice, bountyToken);
                }
            function withdrawBounty() public onlyBountyMaker inState(State.Posted) {
                state = State.Blank;
                ERC20 token = ERC20(bountyToken);
                uint256 tokenBalance = token.balanceOf(this);
                token.transfer(bountyMaker, tokenBalance);
                emit bountyWithdrawn();
                }
            function assignBounty(address _bountyHunter) public onlyBountyMaker inState(State.Posted) {
                state = State.Claimed;
                bountyHunter = _bountyHunter;
                emit bountyClaimed(bountyHunter);
                }
         
           function confirmReceipt() public onlyBountyMaker inState(State.Claimed) {
                state = State.Blank;
                ERC20 token = ERC20(bountyToken);
                uint256 tokenBalance = token.balanceOf(this);
                token.transfer(bountyHunter, tokenBalance);
                }
         
           function initiateDispute() public onlyBountyMakerOrBountyHunter inState(State.Claimed) {
                state = State.Disputed;
                emit Disputed();
                }
         
           function resolveDispute(uint256 MakerAward, uint256 HunterAward) public onlyArbiter inState(State.Disputed) {
                state = State.Blank;
                ERC20 token = ERC20(bountyToken);
                token.transfer(bountyMaker, MakerAward);
                token.transfer(bountyHunter, HunterAward);
                token.transfer(arbiter, arbiterFee);
                emit Resolved(address(this), bountyMaker, bountyHunter);
                }
}