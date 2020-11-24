 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;



contract TxBatching is Ownable {
   
  function payout(address payable[] memory payees, uint256[] memory amounts, address token) public payable {
    uint256 _i;
    IERC20 _token_interface;

    if (token != address(0)) {
      _token_interface = IERC20(token);
    }

    require(payees.length <= 100, 'Max addresses');
    require(payees.length == amounts.length, 'Wrong amounts length');

    for (_i = 0; _i < amounts.length; _i++) {
      if (token == address(0)) {
        payees[_i].transfer(amounts[_i]);
      } else {
        _token_interface.transferFrom(msg.sender, payees[_i], amounts[_i]);
      }
    }
  }

   
  function claimBalance() public onlyOwner {
    uint256 balance = address(this).balance;
    msg.sender.transfer(balance);
  }

   
  function kill() public onlyOwner { selfdestruct(msg.sender); }
}