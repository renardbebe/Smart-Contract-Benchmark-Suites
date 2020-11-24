 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract CoinifinexToken {
	 
	uint256 constant public TOTAL_TOKEN = 10 ** 9;
	uint256 constant public TOKEN_FOR_ICO = 650 * 10 ** 6;
	uint256 constant public TOKEN_FOR_COMPANY = 200 * 10 ** 6;
	uint256 constant public TOKEN_FOR_BONUS = 50 * 10 ** 6;
	
	mapping (address => uint256) public tokenForTeam;
	mapping (address => uint256) public tokenForTeamGet;
	address[] public teamAddress;

	uint public startTime;
	
     
    string public name;
    string public symbol;
    uint8 public decimals = 8;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function CoinifinexToken(
    ) public {
        totalSupply = TOTAL_TOKEN * 10 ** uint256(decimals);  
        name = "Coinifinex";                                  
        symbol = "CFX";                               		 
		
		 
		startTime = 1538265600;  
		
		tokenForTeam[0x4B7786bD8eB1F738699290Bb83cA8E28fEDea4b0] =	20 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0x040440286a443822211dDe0e7E9DA3F49aF2EBC7] =	20 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0x4f7a5A2BafAd56562ac4Ccc85FE004BB84435F71] =	20 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0x7E0D3AaaCB57b0Fd109D9F16e00a375ECa48b41D] =	20 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0xc456aC342f17E7003A03479e275fDA322dE38681] =	500  * 10 ** 3 * 10 ** uint256(decimals);
		tokenForTeam[0xB19d3c4c494B5a3d5d72E0e47076AefC1c643D24] =	300  * 10 ** 3 * 10 ** uint256(decimals);
		tokenForTeam[0x88311485647e19510298d7Dbf0a346D5B808DF03] =	500  * 10 ** 3 * 10 ** uint256(decimals);
		tokenForTeam[0x2f2754e403b58D8F21c4Ba501eff4c5f0dd95b7F] =	500  * 10 ** 3 * 10 ** uint256(decimals);
		tokenForTeam[0x45cD08764e06c1563d4B13b85cCE7082Be0bA6D1] =	100  * 10 ** 3 * 10 ** uint256(decimals);
		tokenForTeam[0xB08924a0D0AF93Fa29e5B0ba103A339704cdeFdb] =	100  * 10 ** 3 * 10 ** uint256(decimals);
		tokenForTeam[0xa8bD7C22d37ea1887b425a9B0A3458A186bf6E77] =	1 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0xe387125f1b24E59f7811d26fbb26bdA1c599b061] =	1 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0xC5b644c5fDe01fce561496179a8Bb7886349bD75] =	1 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0xe4dB43bcB8aecFf58C720F70414A9d36Fd7B9F78] =	5 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0xf28edB52E808cd9DCe18A87fD94D373D6B9f65ae] =	5 * 10 ** 6 * 10 ** uint256(decimals);
		tokenForTeam[0x87CE30ad0B66266b30c206a9e39A3FC0970db5eF] =	5 * 10 ** 6 * 10 ** uint256(decimals);
		
		 
		teamAddress.push(0x4B7786bD8eB1F738699290Bb83cA8E28fEDea4b0);
		teamAddress.push(0x040440286a443822211dDe0e7E9DA3F49aF2EBC7);
		teamAddress.push(0x4f7a5A2BafAd56562ac4Ccc85FE004BB84435F71);
		teamAddress.push(0x7E0D3AaaCB57b0Fd109D9F16e00a375ECa48b41D);
		teamAddress.push(0xc456aC342f17E7003A03479e275fDA322dE38681);
		teamAddress.push(0xB19d3c4c494B5a3d5d72E0e47076AefC1c643D24);
		teamAddress.push(0x88311485647e19510298d7Dbf0a346D5B808DF03);
		teamAddress.push(0x2f2754e403b58D8F21c4Ba501eff4c5f0dd95b7F);
		teamAddress.push(0x45cD08764e06c1563d4B13b85cCE7082Be0bA6D1);
		teamAddress.push(0xB08924a0D0AF93Fa29e5B0ba103A339704cdeFdb);
		teamAddress.push(0xa8bD7C22d37ea1887b425a9B0A3458A186bf6E77);
		teamAddress.push(0xe387125f1b24E59f7811d26fbb26bdA1c599b061);
		teamAddress.push(0xC5b644c5fDe01fce561496179a8Bb7886349bD75);
		teamAddress.push(0xe4dB43bcB8aecFf58C720F70414A9d36Fd7B9F78);
		teamAddress.push(0xf28edB52E808cd9DCe18A87fD94D373D6B9f65ae);
		teamAddress.push(0x87CE30ad0B66266b30c206a9e39A3FC0970db5eF);

		uint arrayLength = teamAddress.length;
		for (uint i=0; i<arrayLength; i++) {
			tokenForTeamGet[teamAddress[i]] = tokenForTeam[teamAddress[i]] * 1 / 10;  
			balanceOf[teamAddress[i]] = tokenForTeamGet[teamAddress[i]];
			tokenForTeam[teamAddress[i]] -= tokenForTeamGet[teamAddress[i]];
		}
		balanceOf[0x966F2884524858326DfF216394a61b9894166c68] = TOKEN_FOR_ICO * 10 ** uint256(decimals);
		balanceOf[0x8eee1a576FaF1332466AaDD9F35Ebf5b6e0162c9] = TOKEN_FOR_COMPANY * 10 ** uint256(decimals);
		balanceOf[0xAe77D38cba1AA5D5288DFC5834a16CcD24dd4041] = TOKEN_FOR_BONUS * 10 ** uint256(decimals);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
	
	function getTeamFund() public {
		 
		if (now >= startTime + 270 days) {
			if (tokenForTeamGet[msg.sender] <  tokenForTeam[msg.sender] * 55 / 100) {
				uint256 getValue2 = tokenForTeam[msg.sender] * 45 / 100;
				tokenForTeamGet[msg.sender] += getValue2;  
				balanceOf[msg.sender] += getValue2;		
			}
		}
		
		 
		if (now >= startTime + 450 days) {
			if (tokenForTeamGet[msg.sender] <  tokenForTeam[msg.sender]) {
				uint256 getValue3 = tokenForTeam[msg.sender] * 45 / 100;
				tokenForTeamGet[msg.sender] += getValue3;  
				balanceOf[msg.sender] += getValue3;	
			}			
		}
    }
}