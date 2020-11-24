 

pragma solidity ^0.4.23;

contract IERC223Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _holder) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
}

contract IERC223Receiver {
  
    
    function tokenFallback(address _from, uint _value, bytes _data) public returns(bool);
}

contract IOwned {
     
    function owner() public pure returns (address) {}

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

contract ICalled is IOwned {
     
    function callers(address) public pure returns (bool) { }

    function appendCaller(address _caller) public;   
    function removeCaller(address _caller) public;   
    
    event AppendCaller(ICaller _caller);
    event RemoveCaller(ICaller _caller);
}

contract ICaller{
	function calledUpdate(address _oldCalled, address _newCalled) public;   
	
	event CalledUpdate(address _oldCalled, address _newCalled);
}

contract IERC20Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _holder) public view returns (uint256);
    function allowance(address _from, address _spender) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _holder, address indexed _spender, uint256 _value);
}

contract IDummyToken is IERC20Token, IERC223Token, IERC223Receiver, ICaller, IOwned{
     
    function operator() public pure returns(ITokenOperator) {}
     
}

contract ISmartToken{
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
	 
}

contract ITokenOperator is ISmartToken, ICalled, ICaller {
     
    function dummy() public pure returns (IDummyToken) {}
    
	function emitEventTransfer(address _from, address _to, uint256 _amount) public;

    function updateChanges(address) public;
    function updateChangesByBrother(address, uint256, uint256) public;
    
    function token_name() public view returns (string);
    function token_symbol() public view returns (string);
    function token_decimals() public view returns (uint8);
    
    function token_totalSupply() public view returns (uint256);
    function token_balanceOf(address _owner) public view returns (uint256);
    function token_allowance(address _from, address _spender) public view returns (uint256);

    function token_transfer(address _from, address _to, uint256 _value) public returns (bool success);
    function token_transfer(address _from, address _to, uint _value, bytes _data) public returns (bool success);
    function token_transfer(address _from, address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success);
    function token_transferFrom(address _spender, address _from, address _to, uint256 _value) public returns (bool success);
    function token_approve(address _from, address _spender, uint256 _value) public returns (bool success);
    
    function fallback(address _from, bytes _data) public payable;                      		 
    function token_fallback(address _token, address _from, uint _value, bytes _data) public returns(bool);     
}

contract IsContract {
	 
    function isContract(address _addr) internal view returns (bool is_contract) {
        uint length;
        assembly {
               
              length := extcodesize(_addr)
        }
        return (length>0);
    }
}

contract Owned is IOwned {
    address public owner;
    address public newOwner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }
}

contract Constant {
	bytes32 internal constant _$FM_							= "$FM";
	bytes32 internal constant _$FM2_						= "$FM2";
	bytes32 internal constant _$FI_							= "$FI";
	bytes32 internal constant _$FO_							= "$FO";
	bytes32 internal constant _$FD_							= "$FD";
	bytes32 internal constant _$FD2_						= "$FD2";
	bytes32 internal constant _$F_							= "$F";
	bytes32 internal constant _$F2R_						= "$F2R";
	bytes32 internal constant _$FR_							= "$FR";
	bytes32 internal constant _ETHER_						= "ETHER"; 
	bytes32 internal constant _Eventer_						= "Eventer"; 
	
	bytes32 internal constant _$FOD_						= "$FOD";
	bytes32 internal constant _totalSupply_					= "totalSupply";
	bytes32 internal constant _balanceOf_					= "balanceOf";
	bytes32 internal constant _lastTime_					= "lastTime";
	bytes32 internal constant _factorDrawLots_				= "factorDrawLots";
	bytes32 internal constant _eraDrawLots_					= "eraDrawLots";
	 
	
	bytes32 internal constant _weightIssue_					= "weightIssue";
	bytes32 internal constant _privatePlacing_				= "privatePlacing";
	bytes32 internal constant _priceInit_					= "priceInit";
	bytes32 internal constant _softCap_						= "softCap";
	bytes32 internal constant _ratioGiftMax_				= "ratioGiftMax";
	bytes32 internal constant _weightOfReserve_				= "weightOfReserve";
	bytes32 internal constant _weightOfTarget_				= "weightOfTarget";
	bytes32 internal constant _decelerationRatioDividend_	= "decelerationRatioDividend";
	bytes32 internal constant _ratioDividend_				= "ratioDividend";
	bytes32 internal constant _investmentSF_				= "investmentSF";
	bytes32 internal constant _investmentEth_				= "investmentEth";
	bytes32 internal constant _profitSF_					= "profitSF";
	bytes32 internal constant _profitEth_					= "profitEth";
	bytes32 internal constant _returnSF_					= "returnSF";
	bytes32 internal constant _returnEth_					= "returnEth";
	bytes32 internal constant _emaDailyYieldSF_				= "emaDailyYieldSF";
	bytes32 internal constant _emaDailyYield_				= "emaDailyYield";
	bytes32 internal constant _timeLastMiningSF_			= "timeLastMiningSF";
	bytes32 internal constant _timeLastMining_				= "timeLastMining";
	bytes32 internal constant _factorMining_				= "factorMining";
	bytes32 internal constant _projectStatus_				= "projectStatus";
	bytes32 internal constant _projectAddr_					= "projectAddr";
	bytes32 internal constant _projectID_					= "projectID";
	bytes32 internal constant _proposeID_					= "proposeID";
	bytes32 internal constant _disproposeID_				= "disproposeID";
	bytes32 internal constant _projects_					= "projects";
	bytes32 internal constant _projectsVoting_				= "projectsVoting";
	bytes32 internal constant _thresholdPropose_			= "thresholdPropose";
	bytes32 internal constant _divisorAbsent_				= "divisorAbsent";
	bytes32 internal constant _timePropose_					= "timePropose";
	bytes32 internal constant _votes_						= "votes";
	bytes32 internal constant _factorDividend_				= "factorDividend";
	bytes32 internal constant _projectIdCount_				= "projectIdCount";
	bytes32 internal constant _projectInfo_					= "projectInfo";
	bytes32 internal constant _recommenders_				= "recommenders";
	bytes32 internal constant _recommendations_				= "recommendations";
	bytes32 internal constant _rewardRecommend_				= "rewardRecommend";
	bytes32 internal constant _halfRewardBalanceOfRecommender_ = "halfRewardBalanceOfRecommender";
	bytes32 internal constant _agents_						= "agents";
	bytes32 internal constant _factorInvitationOfAgent_		= "factorInvitationOfAgent";
	bytes32 internal constant _factorPerformanceOfAgent_	=	"factorPerformanceOfAgent";
	bytes32 internal constant _performanceOfAgent_			= "performanceOfAgent";
	bytes32 internal constant _lastPerformanceOfAgent_		= "lastPerformanceOfAgent";
	 
	bytes32 internal constant _invitationOfAgent_			= "invitationOfAgent";
	 
	bytes32 internal constant _unlockedOfAgent_				= "unlockedOfAgent";
    bytes32 internal constant _agentIssuable_				= "agentIssuable";
    bytes32 internal constant _agentThreshold_              = "agentThreshold";
    bytes32 internal constant _rewardAgent_                 = "rewardAgent";
	bytes32 internal constant _$FP_						    = "$FP";
	bytes32 internal constant _invitation_					= "invitation";
    bytes32 internal constant _agent_						= "agent";
	bytes32 internal constant _channel_					    = "channel";
	bytes32 internal constant _channels_					= "channels";
	bytes32 internal constant _rewardChannel_				= "rewardChannel";
	bytes32 internal constant _rate0DrawLotsOrder_			= "rate0DrawLotsOrder";
	bytes32 internal constant _thresholdAccelDequeueOrder_	= "thresholdAccelDequeueOrder";
	bytes32 internal constant _periodQuotaOrder_			= "periodQuotaOrder";
	bytes32 internal constant _project$f_			        = "project$f";
	bytes32 internal constant _projectEth_			        = "projectEth";
	bytes32 internal constant _etherAmount_			        = "etherAmount";
	bytes32 internal constant _Recommend_			        = "Recommend";
	
	bytes32 internal constant _Price_						= 0xdedeab50b97b0ea258580c72638be71c84db2913f449665c5275cdb7f93c0409;	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	bytes32 internal constant _RecommendPerformance_		= 0xdff59f3289527807a9634eaf83388e1f449e1f0fd75b01141ed33783d13763bb;	 
	bytes32 internal constant _RecommendReward_				= 0xea4e2775055f2f3a80aed6e1fd67888ab02b8cdd276b2983ac96b18965c864ca;	 

     
    uint256 internal constant PROJECT_STATUS_VOTING			= uint256(bytes32("PROJECT_STATUS_VOTING"));
    uint256 internal constant PROJECT_STATUS_FAIL			= uint256(bytes32("PROJECT_STATUS_FAIL"));
    uint256 internal constant PROJECT_STATUS_PASS			= uint256(bytes32("PROJECT_STATUS_PASS"));
    uint256 internal constant PROJECT_STATUS_INVESTED		= uint256(bytes32("PROJECT_STATUS_INVESTED"));
     
    uint256 internal constant PROJECT_STATUS_DISVOTING	    = uint256(bytes32("PROJECT_STATUS_DISVOTING"));
    uint256 internal constant PROJECT_STATUS_DISINVESTING	= uint256(bytes32("PROJECT_STATUS_DISINVESTING"));
    uint256 internal constant PROJECT_STATUS_DISINVESTED	= uint256(bytes32("PROJECT_STATUS_DISINVESTED"));
    
     
     
     
    bytes32 internal constant VOTE_YES                      = "VOTE_YES";
    bytes32 internal constant VOTE_NO                       = "VOTE_NO";
    bytes32 internal constant VOTE_CANCEL                   = "VOTE_CANCEL";
    
}

contract IFund {
	function returnProfit(bytes32 _projectID, uint256 _eth, uint256 _sf) public;
	function returnDisinvestment(bytes32 _projectID, uint256 _eth, uint256 _sf) public;
}

contract IProject is ICaller {
	function invest(bytes32 _projectID, uint256 _eth, uint256 _sf) public;
	function disinvest() public;
}

contract IData is ICalled{
     
    function bu(bytes32) public pure returns(uint256) {}
    function ba(bytes32) public pure returns(address) {}
     
     
     
    
    function bau(bytes32, address) public pure returns(uint256) {}
     
     
     
     
    
    function bbu(bytes32, bytes32) public pure returns(uint256) {}
    function bbs(bytes32, bytes32) public pure returns(string) {}

    function buu(bytes32, uint256) public pure returns(uint256) {}
    function bua(bytes32, uint256) public pure returns(address) {}
	function bus(bytes32, uint256) public pure returns(string) {}
    function bas(bytes32, address) public pure returns(string) {}
     
     
     
    
    function bauu(bytes32, address, uint256) public pure returns(uint256) {}
	 
    function bbau(bytes32, bytes32, address) public pure returns(uint256) {}
     
    function bbaau(bytes32, bytes32, address, address) public pure returns(uint256) {}
    
    function setBU(bytes32 _key, uint256 _value) public;
    function setBA(bytes32 _key, address _value) public;
     
     
     
    
    function setBAU(bytes32 _key, address _addr, uint256 _value) public;
     
     
     
     
    
    function setBBU(bytes32 _key, bytes32 _id, uint256 _value) public;
    function setBBS(bytes32 _key, bytes32 _id, string _value) public;

    function setBUU(bytes32 _key, uint256 _index, uint256 _value) public;
    function setBUA(bytes32 _key, uint256 _index, address _addr) public;
	function setBUS(bytes32 _key, uint256 _index, string _str) public;
     
     

	 
	function setBAUU(bytes32 _key, address _addr, uint256 _index, uint256 _value) public;
    function setBBAU(bytes32 _key, bytes32 _id, address _holder, uint256 _value) public;
	 
    function setBBAAU(bytes32 _key, bytes32 _id, address _from, address _to, uint256 _value) public;
}

contract I$martFund is IFund, IOwned, ICaller {

    function checkQuotaPropose(uint256 _eth, uint256 _sf) public view returns(bool);
    function propose(bytes32 _projectID, bytes32 _proposeID, IProject _project, uint256 _eth, uint256 _sf, string _mixInfo) public;
    function dispropose(bytes32 _projectID, bytes32 _disproposeID, string _mixInfo) public;
	function getVotes(bytes32 _ID, bytes32 _vote) public view returns(uint256);
    function vote(bytes32 _ID, bytes32 _vote) public;

	function forging(uint256 _msm) public;
    function purchase(bool _wantDividend, bool _nonInvate, bytes32 _channel, bytes32 _recommendation) public payable;
    function cancelOrder(uint256 _mso) public returns(uint256 eth);
    function lock4Dividend(uint256 _msd2_ms) public returns(uint256 msd);
    function unlock4Circulate(uint256 _msd) public returns(uint256 msd2);

    function transferMS(address _to, uint256 _ms) public returns (bool success);
    function transferMSI(address _to, uint256 _msi) public returns (bool success);
    function transferMSM(address _to, uint256 _msm) public returns (bool success);

    function apply4Redeem(uint256 _ms) public returns(uint256 ms2r);
    function cancelRedeem(uint256 _ms2r_msr) public returns(uint256 ms);
    function redeem(uint256 msr) public returns(uint256 eth);
    
}

contract SafeMath {
     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x);         
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);         
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        require(_x == 0 || z / _x == _y);         
        return z;
    }
	
	function safeDiv(uint256 _x, uint256 _y)internal pure returns (uint256){
	     
         
         
        return _x / _y;
	}
	
	function ceilDiv(uint256 _x, uint256 _y)internal pure returns (uint256){
		return (_x + _y - 1) / _y;
	}
}

contract Sqrt {
	function sqrt(uint x)public pure returns(uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

contract DataCaller is Owned, ICaller {
    IData public data;
    
    constructor(IData _data) public {
        data = IData(_data);
    }
    
    function calledUpdate(address _oldCalled, address _newCalled) public ownerOnly {
        if(data == _oldCalled) {
            data = IData(_newCalled);
            emit CalledUpdate(_oldCalled, _newCalled);
        }
    }
}

contract GetBU is DataCaller {
    function getBU(bytes32 _key) internal view returns(uint256) {
        return data.bu(_key);        
    }
}

contract SetBU is DataCaller {
    function setBU(bytes32 _key, uint256 _value) internal {
        data.setBU(_key, _value);    
    }
}

contract Disable is Owned {
	bool public disabled;
	
	modifier enabled {
		assert(!disabled);
		_;
	}
	
	function disable(bool _disable) public ownerOnly {
		disabled = _disable;
	}
}

contract IReserve is ICalled {
     
    function balanceOfColdWallet() public pure returns(uint256) {}
    function balanceOfShares() public pure returns(uint256) {}
    function balanceOfOrder() public pure returns(uint256) {}
    function balanceOfMineral() public pure returns(uint256) {}
    function balanceOfProject() public pure returns(uint256) {}
    function balanceOfQueue() public pure returns(uint256) {}
    function headOfQueue() public pure returns(uint256){}
    function tailOfQueue() public view returns(uint256);
    
    function setColdWallet(address _coldWallet, uint256 _ratioAutoSave, uint256 _ratioAutoRemain) public;
	function saveToColdWallet(uint256 _amount) public;
    function restoreFromColdWallet() public payable;

    function depositShares() public payable;
    function depositOrder() public payable;
    function depositMineral() public payable;
    function depositProject() public payable;
    
    function order2Shares(uint256 _amount) public;
    function mineral2Shares(uint256 _amount) public;
    function shares2Project(uint256 _amount)public;
    function project2Shares(uint256 _amount)public;
    function project2Mineral(uint256 _amount) public;
	
    function withdrawShares(uint256 _amount) public returns(bool atonce);
    function withdrawSharesTo(address _to, uint256 _amount) public returns(bool atonce);
    function withdrawOrder(uint256 _amount) public returns(bool atonce);
    function withdrawOrderTo(address _to, uint256 _amount) public returns(bool atonce);
    function withdrawMineral(uint256 _amount) public returns(bool atonce);
    function withdrawMineralTo(address _to, uint256 _amount) public returns(bool atonce);
    function withdrawProject(uint256 _amount)public returns(bool atonce);
    function withdrawProjectTo(address _to, uint256 _amount)public returns(bool atonce);
    
	function() public payable;
}

contract IFormula is IOwned, ICaller {
    uint8 public constant MAX_PRECISION = 127;
    uint32 public constant MAX_WEIGHT = 1000000;
    function reserve() public pure returns(IReserve) { }

    function totalSupply() public view returns (uint256);
    function balanceOf(address _addr)public view returns(uint256);
    function price() view public returns(uint256);
     
    
	function calcTimedQuota(uint256 _rest, uint256 _full, uint256 _timespan, uint256 _period) public pure returns (uint256);
    function calcEma(uint256 _emaPre, uint256 _value, uint32 _timeSpan, uint256 _period) public view returns(uint256);
     
	function calcFactorMining(uint256 _roi) public view returns(uint256);
    
	function calcOrderTo$fAmount(uint256) public view returns(uint256);
	 

    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public constant returns (uint256);
    function calculateRedeemReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public constant returns (uint256);
	
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) public view returns (uint256, uint8);
    function power2(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) public view returns (uint256, uint8);
    function ln(uint256 _numerator, uint256 _denominator) public pure returns (uint256);
    
}

contract I$martFundImpl is ICalled, ICaller {
    uint256 public constant DEQUEUE_DEFAULT             = 0;
    uint256 public constant DEQUEUE_ORDER               = 1;
    uint256 public constant DEQUEUE_INGOT               = 2;
    uint256 public constant DEQUEUE_DOUBLE              = 3;
    uint256 public constant DEQUEUE_DOUBLE_REVERSELY    = 4;
    uint256 public constant DEQUEUE_NONE                = 5;
    
	function data() public pure returns(IData){}
	function reserve() public pure returns(IReserve){}
	function formula() public pure returns(IFormula){}
	
    function dequeueOrder(uint256 gaslimit, bool force) public returns(uint256 dealt);
    function dequeueIngot(uint256 gaslimit, bool force) public returns(uint256 dealt);
    function dequeueAlternately(uint256 gaslimit, bool force) public returns(uint256 dealt);
    function dequeueDouble(uint256 gaslimit, bool force) public returns(uint256 dealt);
    function dequeue(bytes32 _when) public returns(uint256 dealt);

    function getVotes(bytes32 _ID, bytes32 _vote) public view returns(uint256);
	function impl_vote(address _holder, bytes32 _ID, bytes32 _vote) public;
    function impl_forging(address _from, uint256 _msm) public;
    function impl_purchase(address _from, bool _wantDividend, bool _nonInvate, bytes32 _channel) public payable;
    function impl_cancelOrder(address _from, uint256 _msm) public returns(uint256 eth);
    function impl_lock4Dividend(address _from, uint256 _msd2_ms) public returns(uint256 msd);
    function impl_unlock4Circulate(address _from, uint256 _msd) public returns(uint256 msd2);

    function impl_quotaApply4Redeem() view public returns(uint256);
    function impl_apply4Redeem(address _from, uint256 _ms) public returns(uint256 ms2r);
    function impl_cancelRedeem(address _from, uint256 _ms2r_msr) public returns(uint256 ms);
    function impl_redeem(address _from, uint256 msr) public returns(uint256 eth);
}

contract Enabled is Disable, GetBU {
	modifier enabled2 {
        require(!disabled && getBU("dappEnabled") != 0);
        _;
    }
}

contract DisableDapp is SetBU {
	function disableDapp(bool _disable) public ownerOnly {
		setBU("dappEnabled", _disable ? 0 : 1);
	}
}
    
contract GetBA is DataCaller {
    function getBA(bytes32 _key) internal view returns(address) {
        return data.ba(_key);        
    }
}

contract SetBA is DataCaller {
    function setBA(bytes32 _key, address _value) internal {
        data.setBA(_key, _value);    
    }
}

contract GetBAU is DataCaller {
    function getBAU(bytes32 _key, address _addr) internal view returns(uint256) {
        return data.bau(_key, _addr);        
    }
}

contract SetBAU is DataCaller {
    function setBAU(bytes32 _key, address _addr, uint256 _value) internal {
        data.setBAU(_key, _addr, _value);    
    }
}

contract GetBBU is DataCaller {
    function getBBU(bytes32 _key, bytes32 _id) internal view returns(uint256) {
        return data.bbu(_key, _id);
    }
}

contract SetBBU is DataCaller {
    function setBBU(bytes32 _key, bytes32 _id, uint256 _value) internal {
        data.setBBU(_key, _id, _value);    
    }
}

contract GetBBS is DataCaller {
    function getBBS(bytes32 _key, bytes32 _id) internal view returns(string) {
        return data.bbs(_key, _id);
    }
}

contract SetBBS is DataCaller {
    function setBBS(bytes32 _key, bytes32 _id, string _value) internal {
        data.setBBS(_key, _id, _value);    
    }
}

contract GetBUU is DataCaller {
    function getBUU(bytes32 _key, uint256 _index) internal view returns(uint256) {
        return data.buu(_key, _index);        
    }
}

contract SetBUU is DataCaller {
    function setBUU(bytes32 _key, uint256 _index, uint256 _value) internal {
        data.setBUU(_key, _index, _value);    
    }
}

contract GetBUA is DataCaller {
	function getBUA(bytes32 _key, uint256 _index) internal view returns(address) {
        return data.bua(_key, _index);        
    }
}

contract SetBUA is DataCaller {
	function setBUA(bytes32 _key, uint256 _index, address _addr) internal {
        data.setBUA(_key, _index, _addr);        
    }
}

contract GetBUS is DataCaller {
	function getBUS(bytes32 _key, uint256 _index) internal view returns(string) {
        return data.bus(_key, _index);        
    }
}

contract SetBUS is DataCaller {
	function setBUS(bytes32 _key, uint256 _index, string _str) internal {
        data.setBUS(_key, _index, _str);        
    }
}

contract GetBAUU is DataCaller {
	function getBAUU(bytes32 _key, address _addr, uint256 _index) internal view returns(uint256) {
        return data.bauu(_key, _addr, _index);        
    }
}

contract SetBAUU is DataCaller {
	function setBAUU(bytes32 _key, address _addr, uint256 _index, uint256 _value) internal {
        data.setBAUU(_key, _addr, _index, _value);    
    }
}

contract GetBBAU is DataCaller {
    function getBBAU(bytes32 _key, bytes32 _id, address _holder) internal view returns(uint256) {
        return data.bbau(_key, _id, _holder);
    }
}

contract SetBBAU is DataCaller {
    function setBBAU(bytes32 _key, bytes32 _id, address _holder, uint256 _value) internal {
        data.setBBAU(_key, _id, _holder, _value);    
    }
}

contract GetBBAAU is DataCaller {
    function getBBAAU(bytes32 _key, bytes32 _id, address _from, address _to) internal view returns(uint256) {
        return data.bbaau(_key, _id, _from, _to);        
    }
}

contract SetBBAAU is DataCaller {
    function setBBAAU(bytes32 _key, bytes32 _id, address _from, address _to, uint256 _value) internal {
        data.setBBAAU(_key, _id, _from, _to, _value);
    }
}

contract Destructor is Owned{
    function destruct() public ownerOnly {
        selfdestruct(owner);
    }
}

contract $martFund is Constant, I$martFund, IERC223Receiver, SafeMath, Sqrt, DataCaller, Enabled, DisableDapp, GetBA, GetBAU, SetBAU, GetBUA, SetBUA, GetBUU, SetBUU, GetBBU, SetBBU, GetBBAU, GetBUS, SetBUS, GetBAUU, Destructor{     
    IReserve public reserve;
    IFormula public formula;
    I$martFundImpl public impl;
    
    constructor(IData _data, IReserve _reserve, IFormula _formula, I$martFundImpl _impl) DataCaller(_data) public {
        reserve = _reserve;
        formula = _formula;
        impl = _impl;
    }

    function calledUpdate(address _oldCalled, address _newCalled) public ownerOnly {
        if(data == _oldCalled){
            data = IData(_newCalled);
        }else if(reserve == _oldCalled){
            reserve = IReserve(_newCalled);
        }else if(formula == _oldCalled){
            formula = IFormula(_newCalled);
        }else if(impl == _oldCalled){
			impl = I$martFundImpl(_newCalled);
		}else{
            return;
        }
        emit CalledUpdate(_oldCalled, _newCalled);
    }

    function updateEmaDailyYieldSF(uint256 _value) internal  returns(uint256) {
        uint256 ema = getBU("emaDailyYieldSF");
        uint32 timeSpan = uint32(safeSub(now, getBU("timeLastMiningSF")));
		setBU("timeLastMiningSF", now);
        ema = formula.calcEma(ema, _value, timeSpan, 1 days);
        setBU("emaDailyYieldSF", ema);
        return ema;
    }

    function checkQuotaPropose(uint256 _eth, uint256 _sf) public view returns(bool) {
		uint256 totalSupply_ = formula.totalSupply();
		uint256 reserve_ = reserve.balanceOfShares();
		if(_sf * 1 ether > totalSupply_ * getBU("quotaPerProposeSF") || _eth * 1 ether > reserve_ * getBU("quotaPerProposeEth"))
			return false;
		for(uint256 id = getBUU(_projectsVoting_, 0x0); id != 0x0; id = getBUU(_projectsVoting_, id)) {
			_sf  += getBUU(_investmentSF_,  id);
			_eth += getBUU(_investmentEth_, id);
		}
		return _sf * 1 ether <= totalSupply_ * getBU("quotaAllProposeSF") && _eth * 1 ether <= reserve_ * getBU("quotaAllProposeEth");
	}
	
	event Propose(address indexed _holder, bytes32 indexed _projectID, bytes32 _proposeID, IProject _project, uint256 _eth, uint256 _sf);
    function propose(bytes32 _projectID, bytes32 _proposeID, IProject _project, uint256 _eth, uint256 _sf, string _mixInfo) public enabled2 {
		emit Propose(msg.sender, _proposeID, _projectID, _project, _eth, _sf);
		 
		IDummyToken $fd = IDummyToken(getBA(_$FD_));
		require($fd.balanceOf(msg.sender) * 1 ether >= $fd.totalSupply() * getBU(_thresholdPropose_));	 
		if(address(_project) != address(0x0))
			require(checkQuotaPropose(_eth, _sf));			 
        
        if(_projectID == _proposeID) {							 
            uint256 projectID = getBAU(_projectID_, _project);
			uint256 status = getBUU(_projectStatus_, projectID);
			require(projectID == 0 || status == PROJECT_STATUS_FAIL || status == PROJECT_STATUS_DISINVESTED);
            projectID = uint256(_projectID);
            setBAU(_projectID_, _project, projectID);
        }else{
            projectID = uint256(_projectID);
			require(getBAU(_projectID_, _project) == projectID);
			require(getBUU(_projectStatus_, projectID) == PROJECT_STATUS_INVESTED);	 
			uint256 proposeID = getBUU(_proposeID_, projectID);
			require(proposeID == 0 || proposeID == projectID || getBUU(_projectStatus_, proposeID) != PROJECT_STATUS_VOTING);
			uint256 disproposeID = getBUU(_disproposeID_, projectID);
			require(disproposeID == 0 || getBUU(_projectStatus_, disproposeID) == PROJECT_STATUS_FAIL);
        }
       
		proposeID = uint256(_proposeID);
        require(getBUU(_projectStatus_, proposeID) == 0x0);	 
 		setBUU(_proposeID_, projectID, proposeID);
		setBUU(_projectID_, proposeID, projectID);
        setBUU(_projectStatus_, proposeID, PROJECT_STATUS_VOTING);
		setBUU(_timePropose_, proposeID, now);
		setBUA(_projectAddr_, proposeID, _project);
		setBUU(_investmentSF_, proposeID, _sf);
		setBUU(_investmentEth_, proposeID, _eth);
		setBUS(_projectInfo_, proposeID, _mixInfo);
		
		setBUU(_projects_, proposeID, getBUU(_projects_, 0x0));					 
		setBUU(_projects_, 0x0, proposeID);
		setBUU(_projectsVoting_, proposeID, getBUU(_projectsVoting_, 0x0));
		setBUU(_projectsVoting_, 0x0, proposeID);
		
		vote(_proposeID, VOTE_YES);
    }
    
    event Dispropose(address indexed _holder, bytes32 indexed _projectID, bytes32 _disproposeID);
    function dispropose(bytes32 _projectID, bytes32 _disproposeID, string _mixInfo) public enabled2 {
		emit Dispropose(msg.sender, _projectID, _disproposeID);
		 
		uint256 projectID = uint256(_projectID);
		require(getBUU(_projectStatus_, projectID) == PROJECT_STATUS_INVESTED);	 
		uint256 proposeID = getBUU(_proposeID_, projectID);
		require(proposeID == 0 || proposeID == projectID || getBUU(_projectStatus_, proposeID) != PROJECT_STATUS_VOTING);
		uint256 disproposeID = getBUU(_disproposeID_, projectID);
		require(disproposeID == 0 || getBUU(_projectStatus_, disproposeID) == PROJECT_STATUS_FAIL);		 
		disproposeID = uint256(_disproposeID);
		require(getBUU(_projectStatus_, disproposeID) == 0x0);						 
		setBUU(_disproposeID_, projectID, disproposeID);
		setBUU(_projectID_, disproposeID, projectID);
        
		IDummyToken $fd = IDummyToken(getBA(_$FD_));
		require($fd.balanceOf(msg.sender) * 1 ether >= $fd.totalSupply() * getBU(_thresholdPropose_));	 
		setBUU(_projectStatus_, disproposeID, PROJECT_STATUS_DISVOTING);
		setBUU(_timePropose_, disproposeID, now);
		setBUS(_projectInfo_, disproposeID, _mixInfo);
		
		setBUU(_projects_, disproposeID, getBUU(_projects_, 0x0));				 
		setBUU(_projects_, 0x0, disproposeID);
		setBUU(_projectsVoting_, disproposeID, getBUU(_projectsVoting_, 0x0));
		setBUU(_projectsVoting_, 0x0, disproposeID);
		
		vote(_disproposeID, VOTE_YES);
    }
    
    function getVotes(bytes32 _ID, bytes32 _vote) public view returns(uint256) {
		return impl.getVotes(_ID, _vote);
	}
	
    function vote(bytes32 _ID, bytes32 _vote) public enabled2 {
		uint256 status = getBUU(_projectStatus_, uint256(_ID));
		require(status == PROJECT_STATUS_VOTING || status == PROJECT_STATUS_DISVOTING);	 
		impl.impl_vote(msg.sender, _ID, _vote);
    }
    
    function voteYes(bytes32 _projectID) public {
		vote(_projectID, VOTE_YES);
	}
	
    function voteNo(bytes32 _projectID) public {
		vote(_projectID, VOTE_NO);
	}
	
    function voteCancle(bytes32 _projectID) public {
		vote(_projectID, VOTE_CANCEL);
	}
    
	event UpdateProject(address indexed _sender, bytes32 indexed _projectID, address _oldProject, address _newProject);
	function updateProject(address _oldProject, address _newProject) public ownerOnly {
         
        uint256 id = getBAU(_projectID_, _oldProject);
        setBAU(_projectID_, _newProject, id);
        setBAU(_projectID_, _oldProject, 0);
        setBUA(_projectAddr_, id, _newProject);
		emit UpdateProject(msg.sender, bytes32(id), _oldProject, _newProject);
		 
    }
    
	event ReturnProfit(address indexed _sender, bytes32 indexed _projectID, uint256 _eth, uint256 _sf);
	function returnProfit(bytes32 _projectID, uint256 _eth, uint256 _sf) public enabled2 {
	    emit ReturnProfit(msg.sender, _projectID, _eth, _sf);
		 
		uint256 projectID = uint256(_projectID);
		if(_sf > 0) {
			setBUU(_profitSF_, projectID, safeAdd(getBUU(_profitSF_, projectID), _sf));
			setBU(_profitSF_, safeAdd(getBU(_profitSF_), _sf));
			uint256 ema = updateEmaDailyYieldSF(_sf);
			I$FM2_Operator addrMSM2O = I$FM2_Operator(IDummyToken(getBA(_$FM2_)).operator());
			uint256 ratioDividend = addrMSM2O.updateRatioDividend(_sf, ema);
			uint256 dividend = _sf * ratioDividend / 1 ether;
			uint256 supplyOld = formula.totalSupply();
			uint256 supplyNew = safeSub(supplyOld+dividend, _sf);
			uint256 weightOld = getBU(_weightOfReserve_);
			uint256 weightNew = weightOld * supplyOld / supplyNew;
			setBU(_weightOfReserve_, weightNew);
			uint256 reserve_ = reserve.balanceOfShares();
            emit Weight("returnProfit", weightNew, weightOld, reserve_, reserve_, supplyNew, supplyOld, reserve_*1 ether/weightOld*1 ether/supplyOld);
			 
			IDummyToken(getBA(_$F_)).operator().destroy(getBUA(_projectAddr_, projectID), _sf);
			addrMSM2O.dividend(dividend);
			setBU(_returnSF_, safeSub(safeAdd(getBU(_returnSF_), _sf), dividend));
		}
		if(_eth > 0) {
		    setBUU(_profitEth_, projectID, getBUU(_profitEth_, projectID) + _eth);
		    setBU(_profitEth_, getBU(_profitEth_) + _eth);
			reserve.project2Mineral(_eth);
            IEtherToken(getBA(_ETHER_)).destroy(getBUA(_projectAddr_, projectID), _eth);
			 
			 
			 
            setBAU(_projectID_, msg.sender, projectID);
			ITokenOperator(IDummyToken(getBA(_$FM_)).operator()).issue(msg.sender, _eth);
			impl.dequeue("dequeueWhenMining");
		}
	}
	
    event Weight(bytes32 indexed _cause, uint256 _weightNew, uint256 _weightOld, uint256 _reserveNew, uint256 _reserveOld, uint256 _supplyNew, uint256 _supplyOld, uint256 _price);
	event ReturnDisinvestment(address indexed _sender, bytes32 indexed _projectID, uint256 _eth, uint256 _sf);
	function returnDisinvestment(bytes32 _projectID, uint256 _eth, uint256 _sf) public enabled2 {
	    emit ReturnDisinvestment(msg.sender, _projectID, _eth, _sf);
		 
		setBUU(_projectStatus_, uint256(_projectID), PROJECT_STATUS_DISINVESTED);
        setBUU(_disproposeID_, uint256(_projectID), 0);
        address project = getBUA(_projectAddr_, uint256(_projectID));
        setBAU(_projectID_, project, 0); 
		
		uint256 supply = formula.totalSupply();
		uint256 reserve_ = reserve.balanceOfShares(); 
		if(_sf > 0) {
			setBUU(_profitSF_, uint256(_projectID), safeAdd(getBUU(_profitSF_, uint256(_projectID)), _sf));
			setBU(_profitSF_, safeAdd(getBU(_profitSF_), _sf));
			setBU(_returnSF_, safeAdd(getBU(_returnSF_), _sf));
			uint256 weightOld = getBU(_weightOfReserve_);
			uint256 weightNew = weightOld * supply / safeSub(supply, _sf);
			setBU(_weightOfReserve_, weightNew);
            emit Weight("returnDisinvestment", weightNew, weightOld, reserve_, reserve_, safeSub(supply, _sf), supply, reserve_*1 ether/weightOld*1 ether/supply);
			 
			IDummyToken(getBA(_$F_)).operator().destroy(project, _sf);
		}
		if(_eth > 0) {
			setBUU(_profitEth_, uint256(_projectID), getBUU(_profitEth_, uint256(_projectID)) + _eth);
			setBU(_profitEth_, getBU(_profitEth_) + _eth);
			setBU(_returnEth_, getBU(_returnEth_) + _eth);
			weightOld = getBU(_weightOfReserve_);
			weightNew = weightOld * (reserve_+_eth) / reserve_;
			setBU(_weightOfReserve_, weightNew);
            emit Weight("returnDisinvestment", weightNew, weightOld, reserve_+_eth, reserve_, supply, supply, reserve_*1 ether/weightOld*1 ether/supply);
			 
			 
            IEtherToken(getBA(_ETHER_)).destroy(project, _eth);
            reserve.project2Shares(_eth);
		}
	}
	
	function forging(uint256 _msm) public enabled {
        return impl.impl_forging(msg.sender, _msm);
    }
    
    function purchase(bool _wantDividend, bool _nonInvate, bytes32 _channel, bytes32 _recommendation) public payable enabled {
        if(_recommendation != 0)
            IRecommend(getBA(_Recommend_)).bindRecommenderImpl(msg.sender, _recommendation);
		if(msg.value > 0)
			return impl.impl_purchase.value(msg.value)(msg.sender, _wantDividend, _nonInvate, _channel);
    }

    function cancelOrder(uint256 _mso) public enabled returns(uint256 eth) {
        return impl.impl_cancelOrder(msg.sender, _mso);
    }
    
    function lock4Dividend(uint256 _msd2_ms) public enabled returns(uint256 msd) {
        return impl.impl_lock4Dividend(msg.sender, _msd2_ms);
    }
    
    function unlock4Circulate(uint256 _msd) public enabled returns(uint256 msd2) {
        return impl.impl_unlock4Circulate(msg.sender, _msd);
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value, address _token);
	function transferMS(address _to, uint256 _ms) public enabled returns(bool success) {
        return IDummyToken(getBA(_$F_)).operator().token_transfer(msg.sender, _to, _ms);
		emit Transfer(msg.sender, _to, _ms, getBA(_$F_));
		 
    }
    
    function transferMSI(address _to, uint256 _msi) public enabled returns(bool success) {
        return IDummyToken(getBA(_$FI_)).operator().token_transfer(msg.sender, _to, _msi);
		emit Transfer(msg.sender, _to, _msi, getBA(_$FI_));
		 
    }
    
    function transferMSM(address _to, uint256 _msm) public enabled returns(bool success) {
        return IDummyToken(getBA(_$FM_)).operator().token_transfer(msg.sender, _to, _msm);
		emit Transfer(msg.sender, _to, _msm, getBA(_$FM_));
		 
    }

    function apply4Redeem(uint256 _ms) public enabled returns(uint256 msr) {
        return impl.impl_apply4Redeem(msg.sender, _ms);
    }
    
    function cancelRedeem(uint256 _ms2r_msr) public enabled returns(uint256 ms) {
        return impl.impl_cancelRedeem(msg.sender, _ms2r_msr);
    }
    
    function redeem(uint256 _msr) public enabled returns(uint256 eth) {
        return impl.impl_redeem(msg.sender, _msr);
    }

     
    event DequeueOrder(address indexed _holder, uint256 _dealt, uint256 _gaslimit);
	function dequeueOrder(uint256 gaslimit) public enabled returns(uint256 dealt) {		 
		dealt = impl.dequeueOrder(gaslimit, true);
		 
		emit DequeueOrder(msg.sender, dealt, gaslimit);
		 
		 
	}
    
    event DequeueIngot(address indexed _holder, uint256 _dealt, uint256 _gaslimit);
    function dequeueIngot(uint256 gaslimit) public enabled returns(uint256 dealt) {
		dealt = impl.dequeueIngot(gaslimit, true);
		 
		emit DequeueIngot(msg.sender, dealt, gaslimit);
		 
		 
	}

    function nop()public{
    }
	
    function tokenFallback(address _from, uint _value, bytes _data) public enabled2 returns(bool){
        if(msg.sender == getBA(_$F_))
            return true;
        return false;
        _from;  _value; _data;
    }
	
    function() public payable{
        purchase(false, false, 0x0, 0x0);
    }
}

contract IRecommend{
    function bindRecommenderImpl(address _sender, bytes32 _recommendation) public returns(bool);
}

contract I$FM2_Operator {
	function updateRatioDividend(uint256 _amount, uint256 _ema) public returns(uint256 ratioDividend);
    function dequeueIngot(uint256 gaslimit, bool force) public returns(uint256);
	function dividend(uint256 _amount) public;
}

contract IEtherToken {
    function destroy(address _from, uint256 _eth) public;
}