 

pragma solidity ^0.5.10;

 

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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC918Interface {
  function totalSupply() public view returns (uint);
  function getMiningDifficulty() public view returns (uint);
  function getMiningTarget() public view returns (uint);
  function getMiningReward() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
}

 
contract MintHelper is Ownable {
   using SafeMath for uint;

    string public name;
    address public mintableToken;
    mapping(bytes32 => bool) successfulPayments;

    constructor(address mToken, string memory mName)
    public
    {
      mintableToken = mToken;
      name = mName;
    }

    function setMintableToken(address mToken)
    public onlyOwner
    returns (bool)
    {
      mintableToken = mToken;
      return true;
    }

    function paymentSuccessful(bytes32 paymentId) public view returns (bool){
        return (successfulPayments[paymentId] == true);
    }
    
    function proxyMint(uint256 nonce, bytes32 challenge_digest )
    public
    returns (bool)
    {
      require(ERC918Interface(mintableToken).mint(nonce, challenge_digest), "Could not mint token");
      return true;
    }

     
    function withdraw()
    public onlyOwner
    {
        msg.sender.transfer(address(this).balance);
    }

     
    function send(address _tokenAddr, address dest, uint value)
    public onlyOwner
    returns (bool)
    {
     return ERC20Interface(_tokenAddr).transfer(dest, value);
    }

     
    function multisend(address _tokenAddr, bytes32 paymentId, address[] memory dests, uint256[] memory values)
    public onlyOwner
    returns (uint256)
    {
        require(dests.length > 0, "Must have more than 1 destination address");
        require(values.length >= dests.length, "Address to Value array size mismatch");
        require(successfulPayments[paymentId] != true, "Payment ID already exists and was successful");

        uint256 i = 0;
        while (i < dests.length) {
           require(ERC20Interface(_tokenAddr).transfer(dests[i], values[i]));
           i += 1;
        }

        successfulPayments[paymentId] = true;
        return (i);
    }
}