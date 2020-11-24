 

pragma solidity ^0.4.18;

 
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
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

contract Escrow is Ownable {
    using SafeMath for uint256;
    struct EscrowElement {
    bool exists;
    address src;
    address dst;
    uint256 value;
    }

    address public token;
    ERC20 public tok;

    mapping (bytes20 => EscrowElement) public escrows;

     
    uint256 public escrow_fee_numerator;  
    uint256 public escrow_fee_denominator;  



    event EscrowStarted(
    bytes20 indexed escrow_id,
    EscrowElement escrow_element
    );

    event EscrowReleased(
    bytes20 indexed escrow_id,
    EscrowElement escrow_element
    );

    event EscrowCancelled(
    bytes20 indexed escrow_id,
    EscrowElement escrow_element
    );


    event TokenSet(
    address indexed token
    );

    event Withdrawed(
    address indexed dst,
    uint256 value
    );

    function Escrow(address _token){
        token = _token;
        tok = ERC20(_token);
        escrow_fee_numerator = 1;
        escrow_fee_denominator = 25;
    }

    function startEscrow(bytes20 escrow_id, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(escrows[escrow_id].exists != true);
 
        tok.transferFrom(msg.sender, address(this), value);
        EscrowElement memory escrow_element = EscrowElement(true, msg.sender, to, value);
        escrows[escrow_id] = escrow_element;

        emit EscrowStarted(escrow_id, escrow_element);

        return true;
    }

    function releaseEscrow(bytes20 escrow_id, address fee_destination) onlyOwner returns (bool) {
        require(fee_destination != address(0));
        require(escrows[escrow_id].exists == true);

        EscrowElement storage escrow_element = escrows[escrow_id];

        uint256 fee = escrow_element.value.mul(escrow_fee_numerator).div(escrow_fee_denominator);
        uint256 value = escrow_element.value.sub(fee);

 

        tok.transfer(escrow_element.dst, value);
        tok.transfer(fee_destination, fee);


        EscrowElement memory _escrow_element = escrow_element;

        emit EscrowReleased(escrow_id, _escrow_element);

        delete escrows[escrow_id];

        return true;
    }

    function cancelEscrow(bytes20 escrow_id) onlyOwner returns (bool) {
        EscrowElement storage escrow_element = escrows[escrow_id];

 

        tok.transfer(escrow_element.src, escrow_element.value);
        /* Workaround because of lack of feature. See https: 
        EscrowElement memory _escrow_element = escrow_element;


        emit EscrowCancelled(escrow_id, _escrow_element);

        delete escrows[escrow_id];

        return true;
    }

    function withdrawToken(address dst, uint256 value) onlyOwner returns (bool){
        require(dst != address(0));
        require(value > 0);
 
        tok.transfer(dst, value);

        emit Withdrawed(dst, value);

        return true;
    }

    function setToken(address _token) onlyOwner returns (bool){
        require(_token != address(0));
        token = _token;
        tok = ERC20(_token);
        emit TokenSet(_token);

        return true;
    }
     


}