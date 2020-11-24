 

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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract Distribution {

	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	struct distributionInfo {
		ERC20 token;
		uint256 tokenDecimal;
	}

	mapping (address => distributionInfo) wallets;

	function() public payable {
		revert();
	}

	function updateDistributionInfo(ERC20 _token, uint256 _tokenDecimal) public {
		require(_token != address(0));
		require(_tokenDecimal > 0);

		distributionInfo storage wallet = wallets[msg.sender];
		wallet.token = _token;
		wallet.tokenDecimal = _tokenDecimal;
	} 

	function distribute(address[] _addresses, uint256[] _amounts) public {
		require(wallets[msg.sender].token != address(0));
		require(_addresses.length == _amounts.length);

	    for(uint256 i = 0; i < _addresses.length; i++){
	    	require(wallets[msg.sender].token.balanceOf(msg.sender) >= _amounts[i]);
	    	require(wallets[msg.sender].token.allowance(msg.sender,this) >= _amounts[i]);
	    	wallets[msg.sender].token.safeTransferFrom(msg.sender, _addresses[i], _amounts[i]);
	    }
	}

	function getDistributionInfo(address _address) view public returns (ERC20, uint256) {
        return (wallets[_address].token, wallets[_address].tokenDecimal);
    }

}