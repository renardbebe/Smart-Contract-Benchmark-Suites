 

pragma solidity ^0.4.18;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}

contract Ownable {



  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

contract ERC918Interface {
  function totalSupply() public constant returns (uint);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}

 
contract MintHelper is Ownable {

  using SafeMath for uint;

    string public name;


    address public mintableToken;

    address public payoutsWallet;
    address public minterWallet;

    uint public minterFeePercent;


    constructor(address mToken, address pWallet, address mWallet)
    {
      mintableToken = mToken;
      payoutsWallet = pWallet;
      minterWallet = mWallet;
      minterFeePercent = 5;
    }

    function setMintableToken(address mToken)
    public onlyOwner
    returns (bool)
    {
      mintableToken = mToken;
      return true;
    }

    function setPayoutsWallet(address pWallet)
    public onlyOwner
    returns (bool)
    {
      payoutsWallet = pWallet;
      return true;
    }

    function setMinterWallet(address mWallet)
    public onlyOwner
    returns (bool)
    {
      minterWallet = mWallet;
      return true;
    }

    function setMinterFeePercent(uint fee)
    public onlyOwner
    returns (bool)
    {
      require(fee >= 0 && fee <= 100);
      minterFeePercent = fee;
      return true;
    }

    function setName(string newName)
    public onlyOwner
    returns (bool)
    {
      name = newName;
      return true;
    }

    function proxyMint(uint256 nonce, bytes32 challenge_digest )
 
    returns (bool)
    {
       
      uint totalReward = ERC918Interface(mintableToken).getMiningReward();

      uint minterReward = totalReward.mul(minterFeePercent).div(100);
      uint payoutReward = totalReward.sub(minterReward);

       
      require(ERC918Interface(mintableToken).mint(nonce, challenge_digest));

       
      require(ERC20Interface(mintableToken).transfer(minterWallet, minterReward));
      require(ERC20Interface(mintableToken).transfer(payoutsWallet, payoutReward));

      return true;

    }



     
    function withdraw()
    public onlyOwner
    {
        msg.sender.transfer(this.balance);
    }

     
    function send(address _tokenAddr, address dest, uint value)
    public onlyOwner
    returns (bool)
    {
     return ERC20Interface(_tokenAddr).transfer(dest, value);
    }




}