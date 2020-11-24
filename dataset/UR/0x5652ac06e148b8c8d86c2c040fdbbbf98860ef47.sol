 

pragma solidity ^0.4.13;

contract DBC {

     

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Competition is DBC {

     

    struct Hopeful {  
        address fund;  
        address manager;  
        address registrant;  
        bool hasSigned;  
        address buyinAsset;  
        address payoutAsset;  
        uint buyinQuantity;  
        uint payoutQuantity;  
        address payoutAddress;  
        bool isCompeting;  
        bool isDisqualified;  
        uint finalSharePrice;  
        uint finalCompetitionRank;  
    }

    struct HopefulId {
      uint id;  
      bool exists;  
    }

     

     
     
     
    bytes32 public constant TERMS_AND_CONDITIONS = 0x1A46B45CC849E26BB3159298C3C218EF300D015ED3E23495E77F0E529CE9F69E;
    uint public MELON_BASE_UNIT = 10 ** 18;
     
    address public oracle;  
    uint public startTime;  
    uint public endTime;  
    uint public maxbuyinQuantity;  
    uint public maxHopefulsNumber;  
    uint public prizeMoneyAsset;  
    uint public prizeMoneyQuantity;  
    address public MELON_ASSET;  
    ERC20Interface public MELON_CONTRACT;  
    Certifier public CERTIFIER;  
     
    Hopeful[] public hopefuls;  
    mapping (address => address) public registeredFundToRegistrants;  
    mapping(address => HopefulId) public registrantToHopefulIds;  

     

    event Register(uint withId, address fund, address manager);

     

     
     
     
     
     
     
    function termsAndConditionsAreSigned(address byManager, uint8 v, bytes32 r, bytes32 s) view returns (bool) {
        return ecrecover(
             
             
             
             
             
             
             
            keccak256("\x19Ethereum Signed Message:\n32", TERMS_AND_CONDITIONS),
            v,
            r,
            s
        ) == byManager;  
    }

     
    function isOracle() view returns (bool) { return msg.sender == oracle; }

     
     
    function isKYCVerified(address x) view returns (bool) { return CERTIFIER.certified(x); }

     

    function getMelonAsset() view returns (address) { return MELON_ASSET; }

     
    function getHopefulId(address x) view returns (uint) { return registrantToHopefulIds[x].id; }

     
    function getCompetitionStatusOfHopefuls()
        view
        returns(
            address[] fundAddrs,
            address[] fundManagers,
            bool[] areCompeting,
            bool[] areDisqualified
        )
    {
        for (uint i = 0; i <= hopefuls.length - 1; i++) {
            fundAddrs[i] = hopefuls[i].fund;
            fundManagers[i] = hopefuls[i].manager;
            areCompeting[i] = hopefuls[i].isCompeting;
            areDisqualified[i] = hopefuls[i].isDisqualified;
        }
        return (fundAddrs, fundManagers, areCompeting, areDisqualified);
    }

     

    function Competition(
        address ofMelonAsset,
        address ofOracle,
        address ofCertifier,
        uint ofStartTime,
        uint ofMaxbuyinQuantity,
        uint ofMaxHopefulsNumber
    ) {
        MELON_ASSET = ofMelonAsset;
        MELON_CONTRACT = ERC20Interface(MELON_ASSET);
        oracle = ofOracle;
        CERTIFIER = Certifier(ofCertifier);
        startTime = ofStartTime;
        endTime = startTime + 2 weeks;
        maxbuyinQuantity = ofMaxbuyinQuantity;
        maxHopefulsNumber = ofMaxHopefulsNumber;
    }

     
     
     
     
     
     
     
     
    function registerForCompetition(
        address fund,
        address manager,
        address buyinAsset,
        address payoutAsset,
        address payoutAddress,
        uint buyinQuantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        pre_cond(termsAndConditionsAreSigned(manager, v, r, s) && isKYCVerified(msg.sender))
        pre_cond(registeredFundToRegistrants[fund] == address(0) && registrantToHopefulIds[msg.sender].exists == false)
    {
        require(buyinAsset == MELON_ASSET && payoutAsset == MELON_ASSET);
        require(buyinQuantity <= maxbuyinQuantity && hopefuls.length <= maxHopefulsNumber);
        registeredFundToRegistrants[fund] = msg.sender;
        registrantToHopefulIds[msg.sender] = HopefulId({id: hopefuls.length, exists: true});
        Register(hopefuls.length, fund, msg.sender);
        hopefuls.push(Hopeful({
          fund: fund,
          manager: manager,
          registrant: msg.sender,
          hasSigned: true,
          buyinAsset: buyinAsset,
          payoutAsset: payoutAsset,
          payoutAddress: payoutAddress,
          buyinQuantity: buyinQuantity,
          payoutQuantity: 0,
          isCompeting: true,
          isDisqualified: false,
          finalSharePrice: 0,
          finalCompetitionRank: 0
        }));
    }

     
     
     
    function disqualifyHopeful(
        uint withId
    )
        pre_cond(isOracle())
    {
        hopefuls[withId].isDisqualified = true;
    }

     
     
     
     
     
     
    function finalizeAndPayoutForHopeful(
        uint withId,
        uint payoutQuantity,  
        uint finalSharePrice,  
        uint finalCompetitionRank  
    )
        pre_cond(isOracle())
        pre_cond(hopefuls[withId].isDisqualified == false)
        pre_cond(block.timestamp >= endTime)
    {
        hopefuls[withId].finalSharePrice = finalSharePrice;
        hopefuls[withId].finalCompetitionRank = finalCompetitionRank;
        hopefuls[withId].payoutQuantity = payoutQuantity;
        require(MELON_CONTRACT.transfer(hopefuls[withId].registrant, payoutQuantity));
    }

     
     
     
    function changeCertifier(
        address newCertifier
    )
        pre_cond(isOracle())
    {
        CERTIFIER = Certifier(newCertifier);
    }

}

contract ERC20Interface {

     

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     

    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

     

    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
}

contract Owned {
	modifier only_owner { if (msg.sender != owner) return; _; }

	event NewOwner(address indexed old, address indexed current);

	function setOwner(address _new) only_owner { NewOwner(owner, _new); owner = _new; }

	address public owner = msg.sender;
}

contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address _who) constant returns (bool);
	function get(address _who, string _field) constant returns (bytes32) {}
	function getAddress(address _who, string _field) constant returns (address) {}
	function getUint(address _who, string _field) constant returns (uint) {}
}

contract SimpleCertifier is Owned, Certifier {
	modifier only_delegate { if (msg.sender != delegate) return; _; }
	modifier only_certified(address _who) { if (!certs[_who].active) return; _; }

	struct Certification {
		bool active;
		mapping (string => bytes32) meta;
	}

	function certify(address _who) only_delegate {
		certs[_who].active = true;
		Confirmed(_who);
	}
	function revoke(address _who) only_delegate only_certified(_who) {
		certs[_who].active = false;
		Revoked(_who);
	}
	function certified(address _who) constant returns (bool) { return certs[_who].active; }
	function get(address _who, string _field) constant returns (bytes32) { return certs[_who].meta[_field]; }
	function getAddress(address _who, string _field) constant returns (address) { return address(certs[_who].meta[_field]); }
	function getUint(address _who, string _field) constant returns (uint) { return uint(certs[_who].meta[_field]); }
	function setDelegate(address _new) only_owner { delegate = _new; }

	mapping (address => Certification) certs;
	 
	address public delegate = msg.sender;
}