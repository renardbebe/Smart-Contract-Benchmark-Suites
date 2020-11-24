 

pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
	 
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	 
	uint256 public totalSupply;

	 
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	 
	event Burn(address indexed from, uint256 value);

	 
	constructor(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);   
		balanceOf[msg.sender] = totalSupply;                 
		name = tokenName;                                    
		symbol = tokenSymbol;                                
	}

	 
	function _transfer(address _from, address _to, uint _value) internal {
		 
		require(_to != 0x0);
		 
		require(balanceOf[_from] >= _value);
		 
		require(balanceOf[_to] + _value > balanceOf[_to]);
		 
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		 
		balanceOf[_from] -= _value;
		 
		balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
		 
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);      
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
		public
		returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	 
	function burn(uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);    
		balanceOf[msg.sender] -= _value;             
		totalSupply -= _value;                       
		emit Burn(msg.sender, _value);
		return true;
	}

	 
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		require(balanceOf[_from] >= _value);                 
		require(_value <= allowance[_from][msg.sender]);     
		balanceOf[_from] -= _value;                          
		allowance[_from][msg.sender] -= _value;              
		totalSupply -= _value;                               
		emit Burn(_from, _value);
		return true;
	}
}

contract developed {
	address public developer;

	 
	constructor() public {
		developer = msg.sender;
	}

	 
	modifier onlyDeveloper {
		require(msg.sender == developer);
		_;
	}

	 
	function changeDeveloper(address _developer) public onlyDeveloper {
		developer = _developer;
	}

	 
	function withdrawToken(address tokenContractAddress) public onlyDeveloper {
		TokenERC20 _token = TokenERC20(tokenContractAddress);
		if (_token.balanceOf(this) > 0) {
			_token.transfer(developer, _token.balanceOf(this));
		}
	}
}

 
contract ContractVerification is developed {
	bool public contractKilled;

	mapping(bytes32 => string) public stringSettings;   
	mapping(bytes32 => uint256) public uintSettings;    
	mapping(bytes32 => bool) public boolSettings;       

	 
	struct Version {
		bool active;
		uint256[] hostIds;
		string settings;
	}
	struct Host {
		bool active;
		string settings;
	}

	 
	mapping(uint256 => Version) public versions;

	 
	mapping(uint256 => Host) public hosts;

	uint256 public totalVersionSetting;
	uint256 public totalHostSetting;

	 
	event LogUpdateStringSetting(bytes32 indexed name, string value);

	 
	event LogUpdateUintSetting(bytes32 indexed name, uint256 value);

	 
	event LogUpdateBoolSetting(bytes32 indexed name, bool value);

	 
	event LogDeleteStringSetting(bytes32 indexed name);

	 
	event LogDeleteUintSetting(bytes32 indexed name);

	 
	event LogDeleteBoolSetting(bytes32 indexed name);

	 
	event LogAddVersionSetting(uint256 indexed versionNum, bool active, uint256[] hostIds, string settings);

	 
	event LogDeleteVersionSetting(uint256 indexed versionNum);

	 
	event LogUpdateVersionSetting(uint256 indexed versionNum, bool active, uint256[] hostIds, string settings);

	 
	event LogAddHostSetting(uint256 indexed hostId, bool active, string settings);

	 
	event LogDeleteHostSetting(uint256 indexed hostId);

	 
	event LogUpdateHostSetting(uint256 indexed hostId, bool active, string settings);

	 
	event LogAddHostIdToVersion(uint256 indexed hostId, uint256 versionNum, bool success);

	 
	event LogRemoveHostIdAtVersion(uint256 indexed hostId, uint256 versionNum, bool success);

	 
	event LogEscapeHatch();

	 
	constructor() public {}

	 
	 
	 

	 
	function updateStringSetting(bytes32 name, string value) public onlyDeveloper {
		stringSettings[name] = value;
		emit LogUpdateStringSetting(name, value);
	}

	 
	function updateUintSetting(bytes32 name, uint256 value) public onlyDeveloper {
		uintSettings[name] = value;
		emit LogUpdateUintSetting(name, value);
	}

	 
	function updateBoolSetting(bytes32 name, bool value) public onlyDeveloper {
		boolSettings[name] = value;
		emit LogUpdateBoolSetting(name, value);
	}

	 
	function deleteStringSetting(bytes32 name) public onlyDeveloper {
		delete stringSettings[name];
		emit LogDeleteStringSetting(name);
	}

	 
	function deleteUintSetting(bytes32 name) public onlyDeveloper {
		delete uintSettings[name];
		emit LogDeleteUintSetting(name);
	}

	 
	function deleteBoolSetting(bytes32 name) public onlyDeveloper {
		delete boolSettings[name];
		emit LogDeleteBoolSetting(name);
	}

	 
	function addVersionSetting(bool active, uint256[] hostIds, string settings) public onlyDeveloper {
		totalVersionSetting++;

		 
		if (hostIds.length > 0) {
			for(uint256 i=0; i<hostIds.length; i++) {
				require (bytes(hosts[hostIds[i]].settings).length > 0);
			}
		}
		Version storage _version = versions[totalVersionSetting];
		_version.active = active;
		_version.hostIds = hostIds;
		_version.settings = settings;

		emit LogAddVersionSetting(totalVersionSetting, _version.active, _version.hostIds, _version.settings);
	}

	 
	function deleteVersionSetting(uint256 versionNum) public onlyDeveloper {
		delete versions[versionNum];
		emit LogDeleteVersionSetting(versionNum);
	}

	 
	function updateVersionSetting(uint256 versionNum, bool active, uint256[] hostIds, string settings) public onlyDeveloper {
		 
		require (bytes(versions[versionNum].settings).length > 0);

		 
		if (hostIds.length > 0) {
			for(uint256 i=0; i<hostIds.length; i++) {
				require (bytes(hosts[hostIds[i]].settings).length > 0);
			}
		}
		Version storage _version = versions[versionNum];
		_version.active = active;
		_version.hostIds = hostIds;
		_version.settings = settings;

		emit LogUpdateVersionSetting(versionNum, _version.active, _version.hostIds, _version.settings);
	}

	 
	function addHostIdToVersion(uint256 hostId, uint256 versionNum) public onlyDeveloper {
		require (hosts[hostId].active == true);
		require (versions[versionNum].active == true);

		Version storage _version = versions[versionNum];
		if (_version.hostIds.length == 0) {
			_version.hostIds.push(hostId);
			emit LogAddHostIdToVersion(hostId, versionNum, true);
		} else {
			bool exist = false;
			for (uint256 i=0; i < _version.hostIds.length; i++) {
				if (_version.hostIds[i] == hostId) {
					exist = true;
					break;
				}
			}
			if (!exist) {
				_version.hostIds.push(hostId);
				emit LogAddHostIdToVersion(hostId, versionNum, true);
			} else {
				emit LogAddHostIdToVersion(hostId, versionNum, false);
			}
		}
	}

	 
	function removeHostIdAtVersion(uint256 hostId, uint256 versionNum) public onlyDeveloper {
		Version storage _version = versions[versionNum];
		require (versions[versionNum].active == true);
		uint256 hostIdCount = versions[versionNum].hostIds.length;
		require (hostIdCount > 0);

		int256 position = -1;
		for (uint256 i=0; i < hostIdCount; i++) {
			if (_version.hostIds[i] == hostId) {
				position = int256(i);
				break;
			}
		}
		require (position >= 0);

		for (i = uint256(position); i < hostIdCount-1; i++){
			_version.hostIds[i] = _version.hostIds[i+1];
		}
		delete _version.hostIds[hostIdCount-1];
		_version.hostIds.length--;
		emit LogRemoveHostIdAtVersion(hostId, versionNum, true);
	}

	 
	function addHostSetting(bool active, string settings) public onlyDeveloper {
		totalHostSetting++;

		Host storage _host = hosts[totalHostSetting];
		_host.active = active;
		_host.settings = settings;

		emit LogAddHostSetting(totalHostSetting, _host.active, _host.settings);
	}

	 
	function deleteHostSetting(uint256 hostId) public onlyDeveloper {
		require (bytes(hosts[hostId].settings).length > 0);

		delete hosts[hostId];
		emit LogDeleteHostSetting(hostId);
	}

	 
	function updateHostSetting(uint256 hostId, bool active, string settings) public onlyDeveloper {
		require (bytes(hosts[hostId].settings).length > 0);

		Host storage _host = hosts[hostId];
		_host.active = active;
		_host.settings = settings;

		emit LogUpdateHostSetting(hostId, _host.active, _host.settings);
	}

	 
	function escapeHatch() public onlyDeveloper {
		require (contractKilled == false);
		contractKilled = true;
		if (address(this).balance > 0) {
			developer.transfer(address(this).balance);
		}
		emit LogEscapeHatch();
	}

	 
	 
	 

	 
	function getVersionSetting(uint256 versionNum) public constant returns (bool, uint256[], string) {
		Version memory _version = versions[versionNum];
		return (_version.active, _version.hostIds, _version.settings);
	}

	 
	function getLatestVersionSetting() public constant returns (bool, uint256[], string) {
		Version memory _version = versions[totalVersionSetting];
		return (_version.active, _version.hostIds, _version.settings);
	}
}