 

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


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value) returns (bool);
  function approve(address spender, uint value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BatchedPayments is Ownable {

    mapping(bytes32 => bool) successfulPayments;


    function paymentSuccessful(bytes32 paymentId) public constant returns (bool){
        return (successfulPayments[paymentId] == true);
    }

     
    function withdraw() public onlyOwner {
        msg.sender.transfer(this.balance);
    }

    function send(address _tokenAddr, address dest, uint value)
    public onlyOwner
    returns (bool)
    {
     return ERC20(_tokenAddr).transfer(dest, value);
    }

    function multisend(address _tokenAddr, bytes32 paymentId, address[] dests, uint256[] values)
    public onlyOwner
    returns (uint256)
     {

        require(dests.length > 0);
        require(values.length >= dests.length);
        require(successfulPayments[paymentId] != true);

        uint256 i = 0;
        while (i < dests.length) {
           require(ERC20(_tokenAddr).transfer(dests[i], values[i]));
           i += 1;
        }

        successfulPayments[paymentId] = true;

        return (i);

    }



}