 

pragma solidity ^0.5.0;

contract UtilCreateWin {
	uint ethWei = 1 ether;

	function getLevel(uint value) public view returns (uint) {
		if (value >= 1 * ethWei && value <= 5 * ethWei) {
			return 1;
		}
		if (value >= 6 * ethWei && value <= 10 * ethWei) {
			return 2;
		}
		if (value >= 11 * ethWei && value <= 15 * ethWei) {
			return 3;
		}
		return 0;
	}

	function getNodeLevel(uint value) public view returns (uint) {
		if (value >= 1 * ethWei && value <= 5 * ethWei) {
			return 1;
		}
		if (value >= 6 * ethWei && value <= 10 * ethWei) {
			return 2;
		}
		if (value >= 11 * ethWei) {
			return 3;
		}
		return 0;
	}

	function getScByLevel(uint level) public pure returns (uint) {
		if (level == 1) {
			return 5;
		}
		if (level == 2) {
			return 7;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

	function getFireScByLevel(uint level) public pure returns (uint) {
		if (level == 1) {
			return 3;
		}
		if (level == 2) {
			return 6;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

	function getRecommendScaleByLevelAndTim(uint level, uint times) public pure returns (uint){
		if (level == 1 && times == 1) {
			return 50;
		}
		if (level == 2 && times == 1) {
			return 70;
		}
		if (level == 2 && times == 2) {
			return 50;
		}
		if (level == 3) {
			if (times == 1) {
				return 100;
			}
			if (times == 2) {
				return 70;
			}
			if (times == 3) {
				return 50;
			}
			if (times >= 4 && times <= 10) {
				return 10;
			}
			if (times >= 11 && times <= 20) {
				return 5;
			}
			if (times >= 21) {
				return 1;
			}
		}
		return 0;
	}

	function compareStr(string memory _str, string memory str) public pure returns (bool) {
		if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
			return true;
		}
		return false;
	}
}

 
contract Context {
	 
contract Ownable is Context {
	 
	constructor () internal {
		_owner = _msgSender();
	}

	 
	modifier onlyOwner() {
		require(isOwner(), "Ownable: caller is not the owner");
		_;
	}

	 
	function isOwner() public view returns (bool) {
		return _msgSender() == _owner;
	}

	 
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_owner = newOwner;
	}
}

 
library Roles {
	 
	function add(Role storage role, address account) internal {
		require(!has(role, account), "Roles: account already has role");
		role.bearer[account] = true;
	}

	 
	function remove(Role storage role, address account) internal {
		require(has(role, account), "Roles: account does not have role");
		role.bearer[account] = false;
	}

	 
	function has(Role storage role, address account) internal view returns (bool) {
		require(account != address(0), "Roles: account is the zero address");
		return role.bearer[account];
	}
}

 
contract WhitelistAdminRole is Context, Ownable {
	 
library SafeMath {
	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		 
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "mul overflow");

		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0, "div zero");
		 
		uint256 c = a / b;
		 

		return c;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "lower sub bigger");
		uint256 c = a - b;

		return c;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "overflow");

		return c;
	}

	 
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0, "mod zero");
		return a % b;
	}

	 
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? b : a;
	}
}