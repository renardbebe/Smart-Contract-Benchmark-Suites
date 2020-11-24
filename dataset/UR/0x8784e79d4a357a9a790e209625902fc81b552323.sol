 

pragma solidity ^0.4.25;


contract GatlingGun {

	event Authorized(address wallet);
	event Unauthorized(address wallet);
	event NewOwner(address wallet);

	address public owner;

	string public version;

	mapping(address => bool) public authorized;

	constructor(address _owner, string _version) public {
		version = _version;
		owner = _owner;
		emit NewOwner(_owner);
		authorized[_owner] = true;
		emit Authorized(_owner);
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier onlyAuthorized() {
		require(authorized[msg.sender]);
		_;
	}

	function setOwner(address wallet) public onlyOwner {
		owner = wallet;
		emit NewOwner(wallet);
	}

	function authorize(address wallet) public onlyOwner {
		authorized[wallet] = true;
		emit Authorized(wallet);
	}

	function unauthorize(address wallet) public onlyOwner {
		authorized[wallet] = false;
		emit Unauthorized(wallet);
	}

	function fire(bytes, address[] targets, uint256[] lengths, uint256[] values) public onlyAuthorized {
		require(targets.length == lengths.length);
		require(targets.length == values.length);
		uint256 payloadMemoryLocation;
		assembly {
			payloadMemoryLocation := mload(0x40)

			let payloadLengthLocation := add(4, calldataload(4))
			let payloadLength := calldataload(payloadLengthLocation)
			let payloadLocation := add(32, payloadLengthLocation)

			calldatacopy(payloadMemoryLocation, payloadLocation, payloadLength)
			mstore(0x40, add(payloadMemoryLocation, payloadLength))
		}
		bool success;
		uint256 offset = 0;
		for(uint256 i = 0; i < targets.length; i++){
			address target = targets[i];
			uint256 limit = lengths[i];
			uint256 value = values[i];
			assembly {
				success := call(
					gas,
					target,
					value,
					add(payloadMemoryLocation, offset),
					limit,
					0,
					0
				)
			}
			require(success);
			offset += limit;
		}
	}

	function deploy(bytes, uint256 value) public onlyAuthorized returns(address){
		address newContract;
		assembly {
			let payloadMemoryLocation := mload(0x40)

			let payloadLengthLocation := add(4, calldataload(4))
			let payloadLength := calldataload(payloadLengthLocation)
			let payloadLocation := add(32, payloadLengthLocation)

			calldatacopy(payloadMemoryLocation, payloadLocation, payloadLength)
			mstore(0x40, add(payloadMemoryLocation, payloadLength))

			newContract := create (
				value,
				payloadMemoryLocation,
				payloadLength
			)
		}
		require(newContract != address(0x0));
		return newContract;
	}

	function tokenFallback(address, uint, bytes) public pure { }

	function() payable public { }
}

contract DeployGatlingGun {

	string public version = "0.4";

	event NewGunDeployed(address gunAddress, address indexed ownerAddress);

	constructor () public {}

	function deployGatlingGun (address _owner) public {
		emit NewGunDeployed(new GatlingGun(_owner, version), _owner);
	}
}