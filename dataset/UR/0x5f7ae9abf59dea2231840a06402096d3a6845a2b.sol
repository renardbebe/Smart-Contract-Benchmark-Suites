 

pragma solidity ^ 0.4.24;

contract CFG {
	event BuyHistory(
		address indexed addr,
		uint256 value
	);
	
	event RenewHistory(
		address indexed addr,
		uint256 value
	);
	
	event Rescission(
		address indexed addr
	);
	
	event BalancetHistory(
		address indexed addr,
		uint256 value,
		bool isin,
		string t
	);
	
	event ExchangeHistory(
		address indexed addr,
		uint256 price,
		uint256 value,
		uint256 cfg
	);
	
	event SuperPointHistory(
		address indexed addr
	);
}

contract CFGContract is CFG {
	using SafeMath
	for * ;

	address public manager;
	
	uint256 public PERIOD = 864000;
	
	uint256 public MIN = 1000000000000000000;
	
	uint256 public MAX = 39000000000000000000;
	
	address private COM = 0x9Dd7ae0FB7AF52954E709aA77F5541C3ddcF383C;
	
	address private FUND = 0x96eEeB683440c4e5dc5aDD76657fc98edc5B6706;
	
	address private ORI = 0x91819cF3ba30039D1f1f7FD0A0cb7273022FC1c9;
	
	uint256 public consume = 0;
	
	mapping (address => CFGDatasets.PlayerData) public player;
	
	mapping (address => CFGDatasets.PlayerContractData[]) public pcontract;
	
	mapping (address => mapping (uint256 => mapping (uint256 => bool))) public isbonus;
	
	mapping (address => mapping (uint256 => bool)) public ispbonus;
	
	CFGInterface constant private cfgtoken = CFGInterface(0x715a9405944c7e8b6b74374b8eabbb2260eba195);

	uint256 public superPointCount = 0;
	
	uint256 public superPointTotalSupply = 200;
	
	mapping (address => bool) public spoint;
	
	uint256 public rankingId = 0;
	mapping (uint256 => uint256) public rankingTotal;
	
	uint256 public gas = 50000000000000;
	uint256 public bonusGas = 150000000000000;
	
	function CFGContract() {
		manager = msg.sender;
	}
	
	function()
	public
	payable {
		
	}
	
	function exchange()
	public
	payable {
		uint256 _price = getPrice();
		
		uint256 _cfg = msg.value.mul(1000000000000000000)/_price;
		
		require(cfgtoken.transfer(msg.sender,_cfg), "error");
		
		FUND.transfer(msg.value);
		
		emit ExchangeHistory(
			msg.sender,
			_price,
			msg.value,
			_cfg
		);
		
	}
	
	function superpoint()
	public
	payable {
		require(superPointCount < superPointTotalSupply, "The number of superpoint is full.");
		
		require(!spoint[msg.sender], "You have been a superpoint.");
		
		if(superPointCount >= 100){
			require(msg.value == 100000000000000000000, "The payment amount is mismatch.");
		}else if(superPointCount >= 50){
			require(msg.value == 50000000000000000000, "The payment amount is mismatch.");
		}else if(superPointCount >= 20){
			require(msg.value == 30000000000000000000, "The payment amount is mismatch.");
		}else{
			require(msg.value == 15000000000000000000, "The payment amount is mismatch.");
		}
		
		spoint[msg.sender] = true;
		
		superPointCount = superPointCount.add(1);
		
		COM.transfer(msg.value);
		
		emit SuperPointHistory(
			msg.sender
		);
	}
	
	function buy(address _aff)
	public
	payable {
		require(msg.value == (msg.value/1000000000000000000).mul(1000000000000000000), "Please enter an integer.");

		require(msg.value >= MIN, "The minimum quantity is 1.");
		
		require(msg.value <= MAX, "The maximum quantity is 39.");
		
		if(player[msg.sender].aff == address(0)){
			if(_aff == 0x0 || _aff == msg.sender || player[_aff].aff == address(0)){
				_aff = ORI;
			}
			player[msg.sender].aff = _aff;
		}else{
			uint256 _index = pcontract[msg.sender].length.sub(1);
			
			require(msg.value >= pcontract[msg.sender][_index].value, "The quantity must be more than the last contract.");
			
			require(pcontract[msg.sender][_index].isrescission,"The current contract hasn't been released.");
		}
		
		uint256 _cfg = msg.value.mul(10000000000000000)/getPrice();
		
		require(cfgtoken.balanceOf(msg.sender) >= _cfg, "You don't have enough CFG.");
		
		require(cfgtoken.consume(msg.sender,_cfg), "consume error.");
		
		consume = consume.add(_cfg);
		
		address _paddr = getSuperPointAddr(msg.sender);
		
		pcontract[msg.sender].push(CFGDatasets.PlayerContractData(now,msg.value,false,false,_paddr));
		
		COM.transfer(msg.value.mul(4)/100);
		
		emit BuyHistory(
			msg.sender,
			msg.value
		);
	}
	
	function renew()
	public
	payable {
		require(msg.value <= MAX, "The maximun quantity is 39.");
		
		require(msg.value == (msg.value/1000000000000000000).mul(1000000000000000000), "Please enter an integer.");
		
		uint256 _index = pcontract[msg.sender].length.sub(1);
		
		require(!pcontract[msg.sender][_index].isrescission, "The contract has been released, you can't renew the contract.");
		
		uint256 _time = now;
		require(pcontract[msg.sender][_index].time.add(PERIOD) <= _time, "The contract is unexpired, you can't renew the contract.");
		
		require(msg.value >= pcontract[msg.sender][_index].value, "The quantity must be more than the original.");
		
		uint256 _cfg = msg.value.mul(10000000000000000)/getPrice();
		
		require(cfgtoken.balanceOf(msg.sender) >= _cfg, "You don't have enough CFG.");
		
		require(cfgtoken.consume(msg.sender,_cfg), "consume error.");
		
		consume = consume.add(_cfg);
		
		uint256 _income = 0;
		uint256 _value = pcontract[msg.sender][_index].value;
		if(!pcontract[msg.sender][_index].iswithdraw){
			_income = _value;
		}
		if(_value >= 31000000000000000000){
			_income = _income.add(_value.mul(1450)/10000);
		}else if(_value >= 21000000000000000000){
			_income = _income.add(_value.mul(1250)/10000);
		}else if(_value >= 11000000000000000000){
			_income = _income.add(_value.mul(1050)/10000);
		}else if(_value >= 6000000000000000000){
			_income = _income.add(_value.mul(950)/10000);
		}else{
			_income = _income.add(_value.mul(750)/10000);
		}
		player[msg.sender].balance = player[msg.sender].balance.add(_income);
		
		address _paddr = getSuperPointAddr(msg.sender);
		
		pcontract[msg.sender].push(CFGDatasets.PlayerContractData(_time,msg.value,false,false,_paddr));
		
		rankingTotal[rankingId] = rankingTotal[rankingId].add(_value);
		
		COM.transfer(msg.value.mul(4)/100);
		
		emit RenewHistory(
			msg.sender,
			msg.value
		);
		emit BalancetHistory(
			msg.sender,
			_income,
			true,
			"renew"
		);
	}
	
	function getSuperPointAddr(address _addr)
	private
	returns(address){
		if(spoint[_addr]){
			return _addr;
		}else{
			address _aff = player[msg.sender].aff;
			address _paddr = address(0);
			while(_aff != address(0)){
				if(spoint[_aff]){
					_paddr = _aff;
					_aff = address(0);
				}else{
					_aff = player[_aff].aff;
				}
			}
			return _paddr;
		}
	}
	
	function rescission()
	public {
		uint256 _index = pcontract[msg.sender].length.sub(1);
		
		uint256 _time = now;
		require(pcontract[msg.sender][_index].time.add(PERIOD) >= _time, "The contract has been expired.");
		
		uint256 _income = pcontract[msg.sender][_index].value.mul(90)/100;
		player[msg.sender].balance = player[msg.sender].balance.add(_income);
		
		pcontract[msg.sender][_index].isrescission = true;
		pcontract[msg.sender][_index].iswithdraw = true;
		
		emit Rescission(
			msg.sender
		);
		emit BalancetHistory(
			msg.sender,
			_income,
			true,
			"rescission"
		);
	}
	
	function withdraw()
	public {
		uint256 _index = pcontract[msg.sender].length.sub(1);
		
		uint256 _value = player[msg.sender].balance;
		if(!pcontract[msg.sender][_index].isrescission 
			&& pcontract[msg.sender][_index].time.add(PERIOD) <= now
			&& !pcontract[msg.sender][_index].iswithdraw){
			_value = _value.add(pcontract[msg.sender][_index].value);
			
			pcontract[msg.sender][_index].iswithdraw = true;
		}
		
		require(_value > 0, "The balance is 0.");
		
		if(player[msg.sender].balance > 0){
			player[msg.sender].balance = 0;
		}
		
		_value = _value.add(gas);
		
		msg.sender.transfer(_value);
		
		emit BalancetHistory(
			msg.sender,
			_value,
			false,
			"withdraw"
		);
	}
	
	function withdrawBonuss(address[] _addrs,uint256[] _indexs,uint256[] _genNums,uint256[] _myIndexs,uint8[] _types)
	public {
		require(_addrs.length == _indexs.length, "array error 1.");
		require(_addrs.length == _genNums.length, "array error 2.");
		require(_addrs.length == _myIndexs.length, "array error 3.");
		require(_addrs.length == _types.length, "array error 4.");

		uint256 _value = 0;
		for(uint256 i = 0; i < _addrs.length;i++){
			if(_types[i] == 1){
				_value = _value.add(bonus(_addrs[i], _indexs[i], _genNums[i],_myIndexs[i]));
				isbonus[_addrs[i]][_indexs[i]][_genNums[i]] = true;
			}else{
				_value = _value.add(pbonus(_addrs[i], _indexs[i], _myIndexs[i]));
				ispbonus[_addrs[i]][_indexs[i]] = true;
			}
			
		}
		
		_value = _value.add(bonusGas);
		
		msg.sender.transfer(_value);
		emit BalancetHistory(
			msg.sender,
			_value,
			true,
			"bonus"
		);
	}
	
	function withdrawBonus(address _addr,uint256 _index,uint256 _genNum,uint256 _myIndex,uint8 _type)
	public{
		uint256 _value = 0;
		if(_type == 1){
			_value = bonus(_addr, _index, _genNum,_myIndex);
			isbonus[_addr][_index][_genNum] = true;
		}else{
			_value = pbonus(_addr, _index, _myIndex);
			ispbonus[_addr][_index] = true;
		}
		
		msg.sender.transfer(_value);
		emit BalancetHistory(
			msg.sender,
			_value,
			true,
			"bonus"
		);
	}
	
	function bonus(address _addr,uint256 _index,uint256 _genNum,uint256 _myIndex)
	private 
	returns(uint256){
		require(!pcontract[msg.sender][_myIndex].isrescission, "The contract has been released 1.");
		
		require(!pcontract[_addr][_index].isrescission, "The contract has been released 2.");
		
		require(!isbonus[_addr][_index][_genNum], "The dividend has been withdraw.");
		
		require(_index < pcontract[_addr].length.sub(1), "contract error 1.");
		
		require(pcontract[msg.sender][_myIndex].time <= pcontract[_addr][_index].time, "contract error 2.");
		
		require(pcontract[msg.sender][_myIndex.add(1)].time >= pcontract[_addr][_index].time, "contract error 3.");
		
		uint256 _value = pcontract[_addr][_index].value;
		uint256 _myValue = pcontract[msg.sender][_myIndex].value;
		uint256 _genValue = _myValue > _value ? _value : _myValue;
		uint256 _genLevel = 0;
		uint256 _earnings = 0;
		if(_genValue >= 31000000000000000000){
			_genLevel = 20;
			_earnings = _value.mul(1450)/10000;
		}else if(_genValue >= 21000000000000000000){
			_genLevel = 15;
			_earnings = _value.mul(1250)/10000;
		}else if(_genValue >= 11000000000000000000){
			_genLevel = 9;
			_earnings = _value.mul(1050)/10000;
		}else if(_genValue >= 6000000000000000000){
			_genLevel = 6;
			_earnings = _value.mul(950)/10000;
		}else{
			_genLevel = 3;
			_earnings = _value.mul(750)/10000;
		}
		
		require(_genLevel >= _genNum, "you can't get the bonus.");
		
		for(uint256 j = 0; j < _genNum; j++){
			_addr = player[_addr].aff;
		}
		require(_addr == msg.sender, "not yours.");
		
		if(_genNum == 1){
			return _earnings;
		}else if(_genNum == 2){
			return _earnings.mul(20)/100;
		}else if(_genNum == 3){
			return _earnings.mul(10)/100;
		}else if(_genNum > 3 && _genNum <= 10){
			return _earnings.mul(5)/100;
		}else{
			return _earnings.mul(2)/100;
		}
	}
	
	function pbonus(address _addr,uint256 _index,uint256 _myIndex)
	private 
	returns(uint256){
		require(!pcontract[msg.sender][_myIndex].isrescission, "p:The contract has been released.");
		
		require(!pcontract[_addr][_index].isrescission, "p: contract has been released.");
		
		require(!ispbonus[_addr][_index], "p:The dividend has been withdraw.");
		
		require(_index < pcontract[_addr].length.sub(1), "p:contract error 1.");
		 
		require(pcontract[msg.sender][_myIndex].time <= pcontract[_addr][_index].time, "p:contract error 2.");
		
		require(pcontract[msg.sender][_myIndex.add(1)].time >= pcontract[_addr][_index].time, "p:contract error 3.");

		require(pcontract[_addr][_index].paddr == msg.sender, "p:not yours.");
		
		return pcontract[_addr][_index].value.mul(5)/100;
	}
	
	function updateSuperPoint(uint256 _superPointTotalSupply)
	public{
		require(manager == msg.sender, "error");
		superPointTotalSupply = _superPointTotalSupply;
	}
	
	function updateGas(uint256 _gas,uint256 _bonusGas)
	public{
		require(manager == msg.sender, "error");
		require(_gas < 10000000000000000, "error");
		require(_gas > 10000000000000, "error");
		require(_bonusGas >= 0, "error");
		require(_bonusGas >= 0, "error");
		gas = _gas;
		bonusGas = _bonusGas;
	}
	
	function uploadRanking(address[] _addrs,uint256[] _ratios)
	public{
		require(manager == msg.sender, "error 1");
		require(_addrs.length == _ratios.length, "error 2");
		
		uint256 _total = 0;
		for(uint256 j = 0; j < _ratios.length; j++){
			_total = _total.add(_ratios[j]);
		}
		uint256 _rankingTotal = rankingTotal[rankingId].mul(3)/100;
		for(uint256 i = 0; i < _addrs.length; i++){
			require(spoint[_addrs[i]], "error");
			uint256 _value = _rankingTotal.mul(_ratios[i])/_total;
 
			_addrs[i].transfer(_value);
			emit BalancetHistory(
				_addrs[i],
				_value,
				true,
				"ranking"
			);
		}
		rankingId = rankingId.add(1);
		
	}
	
	function balanceOf(address _addr)
	public
	view
	returns(uint256) {
		if(pcontract[_addr].length == 0){
			return 0;
		}
		uint256 _value = player[_addr].balance;
		uint256 _index = pcontract[_addr].length.sub(1);
		if(!pcontract[_addr][_index].isrescission
			&& pcontract[_addr][_index].time.add(PERIOD) <= now
			&& !pcontract[_addr][_index].iswithdraw){
			_value = _value.add(pcontract[_addr][_index].value);
		}
		return _value;
	}
	
	function getPrice()
	public
	view
	returns(uint256){
		uint256 _price = 1000000000000000;
		
		if(consume >= 1000000000000000000000000){
			uint256 _count = consume/1000000000000000000000000;
			for(uint256 i = 0; i < _count; i++ ){
				_price = _price.add(_price/10);
			}
		}
		return _price;
	}
	
	function getPointMsg()
	public
	view
	returns(uint256,uint256,uint256){
		uint256 _price = 0;
		if(superPointCount >= 100){
			_price = 100000000000000000000;
		}else if(superPointCount >= 50){
			_price = 50000000000000000000;
		}else if(superPointCount >= 20){
			_price = 30000000000000000000;
		}else{
			_price = 15000000000000000000;
		}
		return(superPointCount,_price,superPointTotalSupply);
	}
	
	function getTotal()
	public
	view
	returns(uint256){
		return rankingTotal[rankingId];
	}
	
}

interface CFGInterface {
	
	function balanceOf(address _addr) returns(uint256);

	function transfer(address _to, uint256 _value) returns(bool);

	function approve(address _spender, uint256 _value) returns(bool);

	function transferFrom(address _from, address _to, uint256 _value) returns(bool success);
	
	function consume(address _from,uint256 _value) returns(bool success);
}

library CFGDatasets{
	
	struct PlayerData{
		uint256 balance;
		address aff;
	}
	
	struct PlayerContractData{
		uint256 time;
		uint256 value;
		bool iswithdraw;
		bool isrescission;
		address paddr;
	}
	
}

library SafeMath {

	function mul(uint256 a, uint256 b)
	internal
	pure
	returns(uint256 c) {
		if(a == 0) {
			return 0;
		}
		c = a * b;
		require(c / a == b, "mul failed");
		return c;
	}
	
	function sub(uint256 a, uint256 b)
	internal
	pure
	returns(uint256 c) {
		require(b <= a, "sub failed");
		c = a - b;
		require(c <= a, "sub failed");
		return c;
	}

	function add(uint256 a, uint256 b)
	internal
	pure
	returns(uint256 c) {
		c = a + b;
		require(c >= a, "add failed");
		return c;
	}

}