 

pragma solidity ^0.4.19;

contract ADM312 {

  address public COO;
  address public CTO;
  address public CFO;
  address private coreAddress;
  address public logicAddress;
  address public superAddress;

  modifier onlyAdmin() {
    require(msg.sender == COO || msg.sender == CTO || msg.sender == CFO);
    _;
  }
  
  modifier onlyContract() {
    require(msg.sender == coreAddress || msg.sender == logicAddress || msg.sender == superAddress);
    _;
  }
    
  modifier onlyContractAdmin() {
    require(msg.sender == coreAddress || msg.sender == logicAddress || msg.sender == superAddress || msg.sender == COO || msg.sender == CTO || msg.sender == CFO);
     _;
  }
  
  function transferAdmin(address _newAdminAddress1, address _newAdminAddress2) public onlyAdmin {
    if(msg.sender == COO)
    {
        CTO = _newAdminAddress1;
        CFO = _newAdminAddress2;
    }
    if(msg.sender == CTO)
    {
        COO = _newAdminAddress1;
        CFO = _newAdminAddress2;
    }
    if(msg.sender == CFO)
    {
        COO = _newAdminAddress1;
        CTO = _newAdminAddress2;
    }
  }
  
  function transferContract(address _newCoreAddress, address _newLogicAddress, address _newSuperAddress) external onlyAdmin {
    coreAddress  = _newCoreAddress;
    logicAddress = _newLogicAddress;
    superAddress = _newSuperAddress;
    SetCoreInterface(_newLogicAddress).setCoreContract(_newCoreAddress);
    SetCoreInterface(_newSuperAddress).setCoreContract(_newCoreAddress);
  }


}

contract ERC721 {
    
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns (address owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
  
}

contract SetCoreInterface {
   function setCoreContract(address _neWCoreAddress) external; 
}

contract CaData is ADM312, ERC721 {
    
    function CaData() public {
        COO = msg.sender;
        CTO = msg.sender;
        CFO = msg.sender;
        createCustomAtom(0,0,4,0,0,0,0);
    }
    
    function kill() external
	{
	    require(msg.sender == COO);
		selfdestruct(msg.sender);
	}
    
    function() public payable{}
    
    uint public randNonce  = 0;
    
    struct Atom 
    {
      uint64   dna;
      uint8    gen;
      uint8    lev;
      uint8    cool;
      uint32   sons;
      uint64   fath;
	  uint64   moth;
	  uint128  isRent;
	  uint128  isBuy;
	  uint32   isReady;
    }
    
    Atom[] public atoms;
    
    mapping (uint64  => bool) public dnaExist;
    mapping (address => bool) public bonusReceived;
    mapping (address => uint) public ownerAtomsCount;
    mapping (uint => address) public atomOwner;
    
    event NewWithdraw(address sender, uint balance);

    
     
    
    function createCustomAtom(uint64 _dna, uint8 _gen, uint8 _lev, uint8 _cool, uint128 _isRent, uint128 _isBuy, uint32 _isReady) public onlyAdmin {
        require(dnaExist[_dna]==false && _cool+_lev>=4);
        Atom memory newAtom = Atom(_dna, _gen, _lev, _cool, 0, 2**50, 2**50, _isRent, _isBuy, _isReady);
        uint id = atoms.push(newAtom) - 1;
        atomOwner[id] = msg.sender;
        ownerAtomsCount[msg.sender]++;
        dnaExist[_dna] = true;
    }
    
    function withdrawBalance() public payable onlyAdmin {
		NewWithdraw(msg.sender, address(this).balance);
        CFO.transfer(address(this).balance);
    }
    
     
    
    function incRandNonce() external onlyContract {
        randNonce++;
    }
    
    function setDnaExist(uint64 _dna, bool _newDnaLocking) external onlyContractAdmin {
        dnaExist[_dna] = _newDnaLocking;
    }
    
    function setBonusReceived(address _add, bool _newBonusLocking) external onlyContractAdmin {
        bonusReceived[_add] = _newBonusLocking;
    }
    
    function setOwnerAtomsCount(address _owner, uint _newCount) external onlyContract {
        ownerAtomsCount[_owner] = _newCount;
    }
    
    function setAtomOwner(uint _atomId, address _owner) external onlyContract {
        atomOwner[_atomId] = _owner;
    }
    
     
    
    function pushAtom(uint64 _dna, uint8 _gen, uint8 _lev, uint8 _cool, uint32 _sons, uint64 _fathId, uint64 _mothId, uint128 _isRent, uint128 _isBuy, uint32 _isReady) external onlyContract returns (uint id) {
        Atom memory newAtom = Atom(_dna, _gen, _lev, _cool, _sons, _fathId, _mothId, _isRent, _isBuy, _isReady);
        id = atoms.push(newAtom) -1;
    }
	
	function setAtomDna(uint _atomId, uint64 _dna) external onlyAdmin {
        atoms[_atomId].dna = _dna;
    }
	
	function setAtomGen(uint _atomId, uint8 _gen) external onlyAdmin {
        atoms[_atomId].gen = _gen;
    }
    
    function setAtomLev(uint _atomId, uint8 _lev) external onlyContract {
        atoms[_atomId].lev = _lev;
    }
    
    function setAtomCool(uint _atomId, uint8 _cool) external onlyContract {
        atoms[_atomId].cool = _cool;
    }
    
    function setAtomSons(uint _atomId, uint32 _sons) external onlyContract {
        atoms[_atomId].sons = _sons;
    }
    
    function setAtomFath(uint _atomId, uint64 _fath) external onlyContract {
        atoms[_atomId].fath = _fath;
    }
    
    function setAtomMoth(uint _atomId, uint64 _moth) external onlyContract {
        atoms[_atomId].moth = _moth;
    }
    
    function setAtomIsRent(uint _atomId, uint128 _isRent) external onlyContract {
        atoms[_atomId].isRent = _isRent;
    }
    
    function setAtomIsBuy(uint _atomId, uint128 _isBuy) external onlyContract {
        atoms[_atomId].isBuy = _isBuy;
    }
    
    function setAtomIsReady(uint _atomId, uint32 _isReady) external onlyContractAdmin {
        atoms[_atomId].isReady = _isReady;
    }
    
     
    
    mapping (uint => address) tokenApprovals;
    
    function totalSupply() public view returns (uint256 total){
  	    return atoms.length;
  	}
  	
  	function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerAtomsCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        return atomOwner[_tokenId];
    }
      
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        atoms[_tokenId].isBuy  = 0;
        atoms[_tokenId].isRent = 0;
        ownerAtomsCount[_to]++;
        ownerAtomsCount[_from]--;
        atomOwner[_tokenId] = _to;
        Transfer(_from, _to, _tokenId);
    }
  
    function transfer(address _to, uint256 _tokenId) public {
        require(msg.sender == atomOwner[_tokenId]);
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function approve(address _to, uint256 _tokenId) public {
        require(msg.sender == atomOwner[_tokenId]);
        tokenApprovals[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }
    
    function takeOwnership(uint256 _tokenId) public {
        require(tokenApprovals[_tokenId] == msg.sender);
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }
    
}

contract CaBattleInterface {
    function arenaKinds(uint8, uint) public returns (uint8);
    function calculateArenaParams(uint8, uint8, uint24) external returns (uint8[4], uint128);
    function calculateAtomAttack(uint56) external returns (uint16, uint16);
    function calculateBattle(bool, uint56, uint) external;
}

contract CaArena{
    
    function CaArena() public {
        _createArena(0,0, msg.sender);
    }
    
    address public CaDataAddress = 0x9b3554e6fc4f81531f6d43b611258bd1058ef6d5;
    CaData public CaDataContract = CaData(CaDataAddress);
    CaBattleInterface private CaBattleContract;
    
    function kill() external
	{
	    require(msg.sender == CaDataContract.COO());
		selfdestruct(msg.sender);
	}
	
	event NewJoinArena(address sender, uint56 atom, uint arena);
	event NewUnJoinArena(address sender, uint56 atom, uint arena);
	event NewCloseArena(address sender, uint56 winner, uint arena, address winner_addr, address holder, uint128 amount, uint arena1, uint arena2, uint arena3, uint arena4);
	event NewBuyBonus(address sender, uint8 attacks);
	
	function() public payable{}
	
    struct Arena
    {
      bool      active;
      uint8     kind;
      uint8     atm_num;
      uint24    rank;
      uint128   fee;
      uint128   prize;
      uint56    winner;
      address   holder;
    }
    
    Arena[] public arenas;

    uint[] bonusFees = [3 finney, 25 finney, 50 finney, 0, 0, 0, 0, 0];
    uint8[] bonusAttacks = [1, 10, 25, 0, 0, 0, 0, 0];
    
    mapping (uint => mapping (uint8 => uint56)) public arenaAtoms;
    mapping (uint => mapping (uint8 => uint16)) arenaAttacks;
    mapping (uint56 => bool) public atomBattleBusy;
    mapping (uint56 => uint) public atomJoins;
    mapping (uint56 => uint) public atomWins;
    mapping (address => uint8) public addrToBonus;
    mapping (uint => mapping (uint8 => bool)) public arenaToBonus;


    modifier onlyAdmin() {
      require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CFO() || msg.sender == CaDataContract.CTO());
      _;
     }
    
    modifier onlyOwnerOf(uint56 _atomId) {
        require(msg.sender == CaDataContract.atomOwner(uint(_atomId)));
        _;
    }

     
    
    function createArena(uint8 _kind, uint128 _fee) external onlyAdmin {
        _createArena(_kind, _fee, msg.sender);
    }
    
    function setBattleContract(address _newBattleAddress) external onlyAdmin {
        CaBattleContract = CaBattleInterface(_newBattleAddress);
    }
    
  	function setAttackBonusParams(uint _newBonusFee, uint8 _newBonusAttack, uint8 index) external onlyAdmin {
        bonusFees[index] = _newBonusFee;
        bonusAttacks[index] = _newBonusAttack;
  	}
  	
  	function setAttackBonus(uint8 _attacks, address _address) external onlyAdmin {
  	    addrToBonus[_address] = _attacks;
  	}
    
     
    
    function _createArena(uint8 _kind, uint128 _fee, address _holder) private returns (uint id){
        Arena memory newArena = Arena(true, _kind, 0, 0, _fee, 0, 2**50, _holder);
        id = arenas.push(newArena) -1;
    }
    
    function _closeArena(uint _arenaId) private {
        require(arenas[_arenaId].active);
        require(arenas[_arenaId].atm_num>1);
        uint56 winner;
        uint16 winner_attack;
        uint128 winFee;
        uint[4] memory arenasId;
        uint8[4] memory winKind;
        uint8 award = CaBattleContract.arenaKinds(arenas[_arenaId].kind,6);
        for (uint8 i = 0; i < arenas[_arenaId].atm_num; i++)
        {
            atomBattleBusy[arenaAtoms[_arenaId][i]] = false;
            if(arenaAttacks[_arenaId][i] > winner_attack)
            {
                winner = arenaAtoms[_arenaId][i];
                winner_attack = arenaAttacks[_arenaId][i];
            }
        }
        (winKind, winFee) = CaBattleContract.calculateArenaParams(arenas[_arenaId].kind, arenas[_arenaId].atm_num, arenas[_arenaId].rank);
        if(arenas[_arenaId].atm_num < 8)
        {
            award = 1;
        }
        for (i = 0; i < award; i++)
        {
           arenasId[i] = _createArena(winKind[i], arenas[_arenaId].fee+winFee, CaDataContract.atomOwner(uint(winner)));
        }
        atomWins[winner]++;
        arenas[_arenaId].winner = winner;
        arenas[_arenaId].holder.transfer(arenas[_arenaId].prize);
        arenas[_arenaId].active = false;
        NewCloseArena(msg.sender, winner, _arenaId, CaDataContract.atomOwner(uint(winner)), arenas[_arenaId].holder, arenas[_arenaId].prize, arenasId[0], arenasId[1], arenasId[2], arenasId[3]);
    }
    
    function _compValue(uint64 _dna) private pure returns (uint8 compCount) {
        require(_dna < 2 ** 50);
        for (uint8 i = 0; i < 50; i++) 
        {
            if(_dna % 2 == 1) {compCount += 2;}
            _dna /= 2;
        }
    }
    
     
    
    function joinArenaByAtom(uint56 _atomId, uint _arenaId) external payable onlyOwnerOf(_atomId) {
        require(arenas[_arenaId].active);
        require(arenas[_arenaId].fee == msg.value);
        require(atomBattleBusy[_atomId] == false);
        uint64 dna;
        uint8 gen;
        (dna,gen,,,,,,,,) = CaDataContract.atoms(_atomId);
        uint8 comp = _compValue(dna);
        require(gen>=CaBattleContract.arenaKinds(arenas[_arenaId].kind,0));
        require(gen<=CaBattleContract.arenaKinds(arenas[_arenaId].kind,1));
        require(comp>=CaBattleContract.arenaKinds(arenas[_arenaId].kind,2));
        require(comp<=CaBattleContract.arenaKinds(arenas[_arenaId].kind,3));
        require(atomJoins[_atomId]>=CaBattleContract.arenaKinds(arenas[_arenaId].kind,4));
        require(atomWins[_atomId]>=CaBattleContract.arenaKinds(arenas[_arenaId].kind,5));
        uint16 rank;
        uint8 bonus = addrToBonus[msg.sender];
        atomBattleBusy[_atomId] = true;
        atomJoins[_atomId]++;
        arenaAtoms[_arenaId][arenas[_arenaId].atm_num] = _atomId;
        (arenaAttacks[_arenaId][arenas[_arenaId].atm_num],rank) = CaBattleContract.calculateAtomAttack(_atomId);
        if(bonus > 0)
        {
            arenaAttacks[_arenaId][arenas[_arenaId].atm_num] = arenaAttacks[_arenaId][arenas[_arenaId].atm_num] + arenaAttacks[_arenaId][arenas[_arenaId].atm_num]/10;
            addrToBonus[msg.sender] = addrToBonus[msg.sender]-1;
            arenaToBonus[_arenaId][arenas[_arenaId].atm_num] = true;
        }
        arenas[_arenaId].rank = arenas[_arenaId].rank + rank;
        arenas[_arenaId].atm_num++;
        arenas[_arenaId].prize = arenas[_arenaId].prize + arenas[_arenaId].fee - arenas[_arenaId].fee/2;
        CaDataAddress.transfer(arenas[_arenaId].fee/2);
        CaBattleContract.calculateBattle(true,_atomId,_arenaId);
		NewJoinArena(msg.sender,_atomId,_arenaId);
        if(arenas[_arenaId].atm_num==8)
        {
            _closeArena(_arenaId);
            CaBattleContract.calculateBattle(true,0,_arenaId);
        }
  	}
  	
    function unJoinArenaByAtom(uint56 _atomId, uint _arenaId) external onlyOwnerOf(_atomId) {
        require(arenas[_arenaId].active);
        require(atomBattleBusy[_atomId] == true);
        uint8 lev;
        (,,lev,,,,,,,) = CaDataContract.atoms(_atomId);
		require(lev > 2);
        bool finder;
        uint16 rank;
        (,rank) = CaBattleContract.calculateAtomAttack(_atomId);
        atomBattleBusy[_atomId] = false;
        atomJoins[_atomId]--;
        for(uint8 i = 0; i < arenas[_arenaId].atm_num; i++)
        {
            if(finder || arenaAtoms[_arenaId][i]==_atomId)
            {
               arenaAtoms[_arenaId][i] = arenaAtoms[_arenaId][i+1];
               arenaAttacks[_arenaId][i] = arenaAttacks[_arenaId][i+1];
               finder = true; 
            }
        }
        arenas[_arenaId].rank = arenas[_arenaId].rank - rank;
        arenas[_arenaId].atm_num--;
        CaBattleContract.calculateBattle(false,_atomId,_arenaId);
        NewUnJoinArena(msg.sender,_atomId,_arenaId);
  	}
  	
  	function closeArena(uint _arenaId) external payable {
  	    require(arenas[_arenaId].holder == msg.sender);
  	    _closeArena(_arenaId);
  	    CaBattleContract.calculateBattle(false,0,_arenaId);
  	}

  	function buyAttackBonus(uint8 _bonusCode) external payable {
  	    require(_bonusCode < bonusAttacks.length);
  	    require(msg.value == bonusFees[_bonusCode]);
  	    require(addrToBonus[msg.sender] + bonusAttacks[_bonusCode] < 2 ** 8);
  	    addrToBonus[msg.sender] = addrToBonus[msg.sender] + bonusAttacks[_bonusCode];
  	    CaDataAddress.transfer(msg.value);
  	    NewBuyBonus(msg.sender, bonusAttacks[_bonusCode]);
  	}
  	
  	 

  	function arenaAttack(uint _arenaId, uint8 _index) public view returns (uint16 attack){
  	    if(!arenas[_arenaId].active)
  	    {
  	        attack = arenaAttacks[_arenaId][_index];
  	    }
  	}
  	
  	function arenaBonus(uint _arenaId, uint8 _index) public view returns (bool){
        return arenaToBonus[_arenaId][_index];
  	}
  	
  	function arenaAtmNum(uint _arenaId) public view returns (uint8){
  	    return arenas[_arenaId].atm_num;
  	}
  	
  	function arenaSupply() public view returns (uint256){
  	    return arenas.length;
  	}

}