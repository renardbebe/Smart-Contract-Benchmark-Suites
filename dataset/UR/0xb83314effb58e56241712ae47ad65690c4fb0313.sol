 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

contract Collateral is Ownable {
     

    using SafeMath for SafeMath;
    using SafeERC20 for ERC20;

    address public BondAddress;
    address public DepositAddress;  
    address public VoceanAddress;   

    uint public DeductionRate;   
    uint public Total = 100;

    uint public AllowWithdrawAmount;

    ERC20 public BixToken;

    event SetBondAddress(address bond_address);
    event RefundAllCollateral(uint amount);
    event RefundPartCollateral(address addr, uint amount);
    event PayByBondContract(address addr, uint amount);
    event SetAllowWithdrawAmount(uint amount);
    event WithdrawBix(uint amount);

    constructor(address _DepositAddress, ERC20 _BixToken, address _VoceanAddress, uint _DeductionRate) public{
        require(_DeductionRate < 100);
        DepositAddress = _DepositAddress;
        BixToken = _BixToken;
        VoceanAddress = _VoceanAddress;
        DeductionRate = _DeductionRate;

    }

     
    function setBondAddress(address _BondAddress) onlyOwner public {
        BondAddress = _BondAddress;
        emit SetBondAddress(BondAddress);
    }


     
     
    function refundAllCollateral() public {
        require(msg.sender == BondAddress);
        uint current_bix = BixToken.balanceOf(address(this));

        if (current_bix > 0) {
            BixToken.transfer(DepositAddress, current_bix);

            emit RefundAllCollateral(current_bix);
        }


    }

     
     
    function refundPartCollateral() public {

        require(msg.sender == BondAddress);

        uint current_bix = BixToken.balanceOf(address(this));

        if (current_bix > 0) {
             
            uint refund_deposit_addr_amount = get_refund_deposit_addr_amount(current_bix);
            uint refund_vocean_addr_amount = get_refund_vocean_addr_amount(current_bix);

             
            BixToken.transfer(DepositAddress, refund_deposit_addr_amount);
            emit RefundPartCollateral(DepositAddress, refund_deposit_addr_amount);

             
            BixToken.transfer(VoceanAddress, refund_vocean_addr_amount);
            emit RefundPartCollateral(VoceanAddress, refund_vocean_addr_amount);
        }


    }

    function get_refund_deposit_addr_amount(uint current_bix) internal view returns (uint){
        return SafeMath.div(SafeMath.mul(current_bix, SafeMath.sub(Total, DeductionRate)), Total);
    }

    function get_refund_vocean_addr_amount(uint current_bix) internal view returns (uint){
        return SafeMath.div(SafeMath.mul(current_bix, DeductionRate), Total);
    }

     
    function pay_by_bond_contract(address addr, uint amount) public {
        require(msg.sender == BondAddress);
        BixToken.transfer(addr, amount);
        emit PayByBondContract(addr, amount);

    }

     
    function set_allow_withdraw_amount(uint amount) public {
        require(msg.sender == BondAddress);
        AllowWithdrawAmount = amount;
        emit SetAllowWithdrawAmount(amount);
    }

     
    function withdraw_bix() public {
        require(msg.sender == DepositAddress);
        require(AllowWithdrawAmount > 0);
        BixToken.transfer(msg.sender, AllowWithdrawAmount);
         
        AllowWithdrawAmount = 0;
        emit WithdrawBix(AllowWithdrawAmount);
    }

}