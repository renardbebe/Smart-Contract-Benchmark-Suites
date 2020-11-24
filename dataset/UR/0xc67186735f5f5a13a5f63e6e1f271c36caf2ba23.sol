 

 

pragma solidity ^0.5.0;

 
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



contract Commission is Ownable {
	using SafeMath for uint256;

	address payable public wallet;

	constructor(address payable _wallet) public {
		require(_wallet != address(0), "missing wallet");

		wallet = _wallet;
	}

	 

	event HoldexWalletChanged(address indexed wallet);

	function changeHoldexWallet(address payable _wallet) external onlyOwner {
		 
		require(_wallet != address(0), "missing wallet");
		require(_wallet != wallet, "wallets are the same");

		 
		wallet = _wallet;
		emit HoldexWalletChanged(_wallet);
	}

	 

	event CustomerAdded(address indexed customer, address indexed wallet, uint256 commission);
	event CustomerUpdated(address indexed customer, address indexed wallet, uint256 commission);
	event CustomerRemoved(address indexed customer);

	mapping(address => Customer) public customers;

	struct Customer {
		address payable wallet;
		uint256 commissionPercent;
		mapping(bytes32 => Partner) partners;
	}

	function addCustomer(address _customer, address payable _wallet, uint256 _commissionPercent) external onlyOwner {
		 
		require(_customer != address(0), "missing customer address");
		require(_wallet != address(0), "missing wallet address");
		require(_commissionPercent < 100, "invalid commission percent");

		 
		if (customers[_customer].wallet == address(0)) {
			 
			customers[_customer].wallet = _wallet;
			customers[_customer].commissionPercent = _commissionPercent;
			emit CustomerAdded(_customer, _wallet, _commissionPercent);
		} else {
			 
			customers[_customer].wallet = _wallet;
			customers[_customer].commissionPercent = _commissionPercent;
			emit CustomerUpdated(_customer, _wallet, _commissionPercent);
		}
	}

	function customerExists(address _customer) internal view {
		require(customers[_customer].wallet != address(0), "customer does not exist");
	}

	function removeCustomer(address _customer) external onlyOwner {
		 
		require(_customer != address(0), "missing customer address");

		 
		customerExists(_customer);

		 
		delete customers[_customer];
		emit CustomerRemoved(_customer);
	}

	 

	event PartnerAdded(address indexed customer, bytes32 partner, address indexed wallet, uint256 commission);
	event PartnerUpdated(address indexed customer, bytes32 partner, address indexed wallet, uint256 commission);
	event PartnerRemoved(address indexed customer, bytes32 partner);

	struct Partner {
		address payable wallet;
		uint256 commissionPercent;
	}

	function addPartner(address _customer, bytes32 _partner, address payable _wallet, uint256 _commissionPercent) external onlyOwner {
		 
		require(_customer != address(0), "missing customer address");
		require(_partner[0] != 0, "missing partner id");
		require(_wallet != address(0), "missing wallet address");
		require(_commissionPercent > 0 && _commissionPercent < 100, "invalid commission percent");

		 
		customerExists(_customer);

		 
		if (customers[_customer].partners[_partner].wallet == address(0)) {
			 
			customers[_customer].partners[_partner] = Partner(_wallet, _commissionPercent);
			emit PartnerAdded(_customer, _partner, _wallet, _commissionPercent);
		} else {
			 
			customers[_customer].partners[_partner].wallet = _wallet;
			customers[_customer].partners[_partner].commissionPercent = _commissionPercent;
			emit PartnerUpdated(_customer, _partner, _wallet, _commissionPercent);
		}
	}

	function removePartner(address _customer, bytes32 _partner) external onlyOwner {
		 
		require(_customer != address(0), "missing customer address");
		require(_partner[0] != 0, "missing partner id");

		 
		customerExists(_customer);
		 
		require(customers[_customer].partners[_partner].wallet != address(0), "partner does not exist");

		 
		delete customers[_customer].partners[_partner];
		emit PartnerRemoved(_customer, _partner);
	}

	 

	function transfer(bool holdex, bytes32[] calldata _partners) external payable {
		 
		require(msg.value > 0, "transaction value is 0");

		 
		customerExists(msg.sender);

		 
		if (customers[msg.sender].commissionPercent == 0 || !holdex && _partners.length == 0) {
			 
			customers[msg.sender].wallet.transfer(msg.value);
			return;
		}

		 
		if (holdex || _partners.length > 0) {
			 

			 
			uint256 customerRevenue = msg.value.div(100).mul(100 - customers[msg.sender].commissionPercent);
			 
			customers[msg.sender].wallet.transfer(customerRevenue);

			 
			uint256 holdexRevenue = msg.value.sub(customerRevenue);
			uint256 alreadySentPercent = 0;
			 
			for (uint256 i = 0; i < _partners.length; i++) {
				Partner memory p = customers[msg.sender].partners[_partners[i]];
				require(p.commissionPercent > 0, "invalid partner");

				 
				uint256 partnerRevenue = holdexRevenue.div(100 - alreadySentPercent).mul(p.commissionPercent);
				p.wallet.transfer(partnerRevenue);

				 
				alreadySentPercent = alreadySentPercent.add(p.commissionPercent);
				holdexRevenue = holdexRevenue.sub(partnerRevenue);
			}

			require(holdexRevenue > 0, "holdex revenue is 0");
			 
			wallet.transfer(holdexRevenue);
			return;
		}

		revert("can not transfer");
	}
}