 

pragma solidity ^0.4.25;


 
 
 library SafeMath256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if(a==0 || b==0)
        return 0;  
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b>0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
   require( b<= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  
}


 
contract ERC20 {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  

}


 
 
 
 

contract Ownable {


 
 
 
 

  string [] ownerName;  
  mapping (address=>bool) owners;
  mapping (address=>uint256) ownerToProfile;
  address owner;

 
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);
   

    
    
    

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
    uint256 idx = ownerName.push("SAMRET WAJANASATHIAN");
    ownerToProfile[msg.sender] = idx;

  }

 

  function isContract(address _addr) internal view returns(bool){
     uint256 length;
     assembly{
      length := extcodesize(_addr)
     }
     if(length > 0){
       return true;
    }
    else {
      return false;
    }

  }

 
 
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

 
 
  
  function transferOwnership(address newOwner,string newOwnerName) public onlyOwner{
    require(isContract(newOwner) == false);
    uint256 idx;
    if(ownerToProfile[newOwner] == 0)
    {
    	idx = ownerName.push(newOwnerName);
    	ownerToProfile[newOwner] = idx;
    }


    emit OwnershipTransferred(owner,newOwner);
    owner = newOwner;

  }

 
 
  
  modifier onlyOwners(){
    require(owners[msg.sender] == true);
    _;
  }

 
 
  
  function addOwner(address newOwner,string newOwnerName) public onlyOwners{
    require(owners[newOwner] == false);
    require(newOwner != msg.sender);
    if(ownerToProfile[newOwner] == 0)
    {
    	uint256 idx = ownerName.push(newOwnerName);
    	ownerToProfile[newOwner] = idx;
    }
    owners[newOwner] = true;
    emit AddOwner(newOwner,newOwnerName);
  }

 
 
 
 

  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);   
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }
 
 
 

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

 
 

  function getOwnerName(address ownerAddr) public view returns(string){
  	require(ownerToProfile[ownerAddr] > 0);

  	return ownerName[ownerToProfile[ownerAddr] - 1];
  }
}

 
 

contract ControlToken is Ownable{
	
	mapping (address => bool) lockAddr;
	address[] lockAddrList;
	uint32  unlockDate;

     bool disableBlock;
     bool call2YLock;

	mapping(address => bool) allowControl;
	address[] exchangeAddress;
	uint32    exchangeTimeOut;

	event Call2YLock(address caller);

 
 
 

	constructor() public{
		unlockDate = uint32(now) + 36500 days;   
		
	}

 
 

	function setExchangeAddr(address _addr) onlyOwners public{
		uint256 numEx = exchangeAddress.push(_addr);
		if(numEx == 1){
			exchangeTimeOut = uint32(now + 180 days);
		}
	}

 
 

	function setExchangeTimeOut(uint32 timStemp) onlyOwners public{
		exchangeTimeOut = timStemp;
	}

 
 
 
 
 
 
 
 
 

	function start2YearLock() onlyOwners public{
		if(call2YLock == false){
			unlockDate = uint32(now) + 730 days;
			call2YLock = true;

			emit Call2YLock(msg.sender);
		}
	
	}

	function lockAddress(address _addr) internal{
		if(lockAddr[_addr] == false)
		{
			lockAddr[_addr] = true;
			lockAddrList.push(_addr);
		}
	}

	function isLockAddr(address _addr) public view returns(bool){
		return lockAddr[_addr];
	}

 
	
	function addLockAddress(address _addr) onlyOwners public{
		if(lockAddr[_addr] == false)
		{
			lockAddr[_addr] = true;
			lockAddrList.push(_addr);		
		}
	}

 
 
 
 

	function unlockAllAddress() public{
		if(uint32(now) >= unlockDate)
		{
			for(uint256 i=0;i<lockAddrList.length;i++)
			{
				lockAddr[lockAddrList[i]] = false;
			}
		}
	}

 
 
 
 

	function setAllowControl(address _addr) internal{
		if(allowControl[_addr] == false)
			allowControl[_addr] = true;
	}

 
 

	function checkAllowControl(address _addr) public view returns(bool){
		return allowControl[_addr];
	}

 
 
 
 
 
 
 
   
    function setDisableLock() public{
    	if(uint256(now) >= exchangeTimeOut && exchangeAddress.length > 0)
    	{
      	if(disableBlock == false)
      		disableBlock = true;
      	}
    }

}

 
 
 
 

contract KYC is ControlToken{


	struct KYCData{
		bytes8    birthday;  
		bytes16   phoneNumber; 

		uint16    documentType;  
		uint32    createTime;  
		 
		bytes32   peronalID;   
		 
		bytes32    name;
		bytes32    surName;
		bytes32    email;
		bytes8	  password;
	}

	KYCData[] internal kycDatas;

	mapping (uint256=>address) kycDataForOwners;
	mapping (address=>uint256) OwnerToKycData;

	mapping (uint256=>address) internal kycSOSToOwner;  


	event ChangePassword(address indexed owner_,uint256 kycIdx_);
	event CreateKYCData(address indexed owner_, uint256 kycIdx_);

	 

	function getKYCData(uint256 _idx) onlyOwners view public returns(bytes16 phoneNumber_,
										 							  bytes8  birthday_,
										 							  uint16 documentType_,
										 							  bytes32 peronalID_,
										 							  bytes32 name_,
										 							  bytes32 surname_,
										 							  bytes32 email_){
		require(_idx <= kycDatas.length && _idx > 0,"ERROR GetKYCData 01");
		KYCData memory _kyc;
		uint256  kycKey = _idx - 1; 
		_kyc = kycDatas[kycKey];

		phoneNumber_ = _kyc.phoneNumber;
		birthday_ = _kyc.birthday;
		documentType_ = _kyc.documentType;
		peronalID_ = _kyc.peronalID;
		name_ = _kyc.name;
		surname_ = _kyc.surName;
		email_ = _kyc.email;

		} 

	 
	function getKYCDataByAddr(address _addr) onlyOwners view public returns(bytes16 phoneNumber_,
										 							  bytes8  birthday_,
										 							  uint16 documentType_,
										 							  bytes32 peronalID_,
										 							  bytes32 name_,
										 							  bytes32 surname_,
										 							  bytes32 email_){
		require(OwnerToKycData[_addr] > 0,"ERROR GetKYCData 02");
		KYCData memory _kyc;
		uint256  kycKey = OwnerToKycData[_addr] - 1; 
		_kyc = kycDatas[kycKey];

		phoneNumber_ = _kyc.phoneNumber;
		birthday_ = _kyc.birthday;
		documentType_ = _kyc.documentType;
		peronalID_ = _kyc.peronalID;
		name_ = _kyc.name;
		surname_ = _kyc.surName;
		email_ = _kyc.email;

		} 

	 
	function getKYCData() view public returns(bytes16 phoneNumber_,
										 					 bytes8  birthday_,
										 					 uint16 documentType_,
										 					 bytes32 peronalID_,
										 					 bytes32 name_,
										 					 bytes32 surname_,
										 					 bytes32 email_){
		require(OwnerToKycData[msg.sender] > 0,"ERROR GetKYCData 03");  
		uint256 id = OwnerToKycData[msg.sender] - 1;

		KYCData memory _kyc;
		_kyc = kycDatas[id];

		phoneNumber_ = _kyc.phoneNumber;
		birthday_ = _kyc.birthday;
		documentType_ = _kyc.documentType;
		peronalID_ = _kyc.peronalID;
		name_ = _kyc.name;
		surname_ = _kyc.surName;
		email_ = _kyc.email;
	}

 
	function changePassword(bytes8 oldPass_, bytes8 newPass_) public returns(bool){
		require(OwnerToKycData[msg.sender] > 0,"ERROR changePassword"); 
		uint256 id = OwnerToKycData[msg.sender] - 1;
		if(kycDatas[id].password == oldPass_)
		{
			kycDatas[id].password = newPass_;
			emit ChangePassword(msg.sender, id);
		}
		else
		{
			assert(kycDatas[id].password == oldPass_);
		}

		return true;


	}

	 
	function createKYCData(bytes32 _name, bytes32 _surname, bytes32 _email,bytes8 _password, bytes8 _birthday,bytes16 _phone,uint16 _docType,bytes32 _peronalID,address  _wallet) onlyOwners public returns(uint256){
		uint256 id = kycDatas.push(KYCData(_birthday, _phone, _docType, uint32(now) ,_peronalID, _name, _surname, _email, _password));
		uint256 sosHash = uint256(keccak256(abi.encodePacked(_name, _surname , _email, _password)));

		OwnerToKycData[_wallet] = id;
		kycDataForOwners[id] = _wallet; 
		kycSOSToOwner[sosHash] = _wallet; 
		emit CreateKYCData(_wallet,id);

		return id;
	}

	function maxKYCData() public view returns(uint256){
		return kycDatas.length;
	}

	function haveKYCData(address _addr) public view returns(bool){
		if(OwnerToKycData[_addr] > 0) return true;
		else return false;
	}

}

 

contract StandarERC20 is ERC20{
	using SafeMath256 for uint256;  
     
     mapping (address => uint256) balance;
     mapping (address => mapping (address=>uint256)) allowed;


     uint256 public totalSupply_;  
     

     address[] public  holders;
     mapping (address => uint256) holderToId;


     event Transfer(address indexed from,address indexed to,uint256 value);
     event Approval(address indexed owner,address indexed spender,uint256 value);


 
    function totalSupply() public view returns (uint256){
     	return totalSupply_;
    }

     function balanceOf(address _walletAddress) public view returns (uint256){
        return balance[_walletAddress]; 
     }

 
     function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
        }

 
     function transfer(address _to, uint256 _value) public returns (bool){
        require(_value <= balance[msg.sender]);
        require(_to != address(0));
        
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);

        emit Transfer(msg.sender,_to,_value); 
        return true;

     }
 
     function approve(address _spender, uint256 _value)
            public returns (bool){
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }


 
 
 
      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from]);
               require(_value <= allowed[_from][msg.sender]); 
               require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

              emit Transfer(_from, _to, _value);
              return true;
      }

 
 
     function addHolder(address _addr) internal{
     	if(holderToId[_addr] == 0)
     	{
     		uint256 idx = holders.push(_addr);
     		holderToId[_addr] = idx;
     	}
     }

 
     function getMaxHolders() external view returns(uint256){
     	return holders.length;
     }

 
     function getHolder(uint256 idx) external view returns(address){
     	return holders[idx];
     }
     
}


 
 
 

contract FounderAdvisor is StandarERC20,Ownable,KYC {

	uint256 FOUNDER_SUPPLY = 5000000 ether;
	uint256 ADVISOR_SUPPLY = 4000000 ether;

	address[] advisors;
	address[] founders;

	mapping (address => uint256) advisorToID;
	mapping (address => uint256) founderToID;
	 
	 

	bool  public closeICO;

	 

	uint256 public TOKEN_PER_FOUNDER = 0 ether; 
	uint256 public TOKEN_PER_ADVISOR = 0 ether;

	event AddFounder(address indexed newFounder,string nane,uint256  curFoounder);
	event AddAdvisor(address indexed newAdvisor,string name,uint256  curAdvisor);
	event CloseICO();

	event RedeemAdvisor(address indexed addr_, uint256 value);
	event RedeemFounder(address indexed addr_, uint256 value);

	event ChangeAdvisorAddr(address indexed oldAddr_, address indexed newAddr_);
	event ChangeFounderAddr(address indexed oldAddr_, address indexed newAddr_);


 
 
	function addFounder(address newAddr, string _name) onlyOwners external returns (bool){
		require(closeICO == false);
		require(founderToID[newAddr] == 0);

		uint256 idx = founders.push(newAddr);
		founderToID[newAddr] = idx;
		emit AddFounder(newAddr, _name, idx);
		return true;
	}

 

	function addAdvisor(address newAdvis, string _name) onlyOwners external returns (bool){
		require(closeICO == false);
		require(advisorToID[newAdvis] == 0);

		uint256 idx = advisors.push(newAdvis);
		advisorToID[newAdvis] = idx;
		emit AddAdvisor(newAdvis, _name, idx);
		return true;
	}

 
 

	function changeAdvisorAddr(address oldAddr, address newAddr) onlyOwners external returns(bool){
		require(closeICO == false);
		require(advisorToID[oldAddr] > 0);  

		uint256 idx = advisorToID[oldAddr];

		advisorToID[newAddr] = idx;
		advisorToID[oldAddr] = 0;

		advisors[idx - 1] = newAddr;

		emit ChangeAdvisorAddr(oldAddr,newAddr);
		return true;
	}

 
 
	function changeFounderAddr(address oldAddr, address newAddr) onlyOwners external returns(bool){
		require(closeICO == false);
		require(founderToID[oldAddr] > 0);

		uint256 idx = founderToID[oldAddr];

		founderToID[newAddr] = idx;
		founderToID[oldAddr] = 0;
		founders[idx - 1] = newAddr;

		emit ChangeFounderAddr(oldAddr, newAddr);
		return true;
	}

	function isAdvisor(address addr) public view returns(bool){
		if(advisorToID[addr] > 0) return true;
		else return false;
	}

	function isFounder(address addr) public view returns(bool){
		if(founderToID[addr] > 0) return true;
		else return false;
	}
}

 
 
 
 

contract MyToken is FounderAdvisor {
	 using SafeMath256 for uint256;  
     mapping(address => uint256) privateBalance;


     event SOSTranfer(address indexed oldAddr_, address indexed newAddr_);

 
 
 

     function transfer(address _to, uint256 _value) public returns (bool){
     	if(lockAddr[msg.sender] == true)  
     	{
     		require(lockAddr[_to] == true);
     	}

     	 
     	if(privateBalance[msg.sender] < _value){
     		if(disableBlock == false)
     		{
        		require(OwnerToKycData[msg.sender] > 0,"You Not have permission to Send");
        		require(OwnerToKycData[_to] > 0,"You not have permission to Recieve");
        	}
   		 }
        
         addHolder(_to);

        if(super.transfer(_to, _value) == true)
        {
        	 
        	if(privateBalance[msg.sender] <= _value)
        	{
        		privateBalance[_to] += privateBalance[msg.sender];
        		privateBalance[msg.sender] = 0;
        	}
        	else
        	{
        		privateBalance[msg.sender] = privateBalance[msg.sender].sub(_value);
        		privateBalance[_to] = privateBalance[_to].add(_value);
        	}

        	return true;
        }


        return false;

     }

 
 
 

      function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
            require(lockAddr[_from] == false);  

            if(privateBalance[_from] < _value)
            {
            	if(disableBlock == false)
            	{	
         	    	require(OwnerToKycData[msg.sender] > 0, "You Not Have permission to Send");
            		require(OwnerToKycData[_to] > 0,"You not have permission to recieve");
        		}
        	}
           
            addHolder(_to);

            if(super.transferFrom(_from, _to, _value) == true)
            {
            	 if(privateBalance[msg.sender] <= _value)
        		{
        			privateBalance[_to] += privateBalance[msg.sender];
        			privateBalance[msg.sender] = 0;
        		}
        		else
        		{
        			privateBalance[msg.sender] = privateBalance[msg.sender].sub(_value);
        			privateBalance[_to] = privateBalance[_to].add(_value);
        		}

        		return true;
            }
            return false;

      }

       
       
       
       
      function sosTransfer(bytes32 _name, bytes32 _surname, bytes32 _email,bytes8 _password,address _newAddr) onlyOwners public returns(bool){

      	uint256 sosHash = uint256(keccak256(abi.encodePacked(_name, _surname , _email, _password)));
      	address oldAddr = kycSOSToOwner[sosHash];
      	uint256 idx = OwnerToKycData[oldAddr];

      	require(allowControl[oldAddr] == false);
      	if(idx > 0)
      	{
      		idx = idx - 1;
      		if(kycDatas[idx].name == _name &&
      		   kycDatas[idx].surName == _surname &&
      		   kycDatas[idx].email == _email &&
      		   kycDatas[idx].password == _password)
      		{

      			kycSOSToOwner[sosHash] = _newAddr;
      			OwnerToKycData[oldAddr] = 0;  
      			OwnerToKycData[_newAddr] = idx;
      			kycDataForOwners[idx] = _newAddr;

      			emit SOSTranfer(oldAddr, _newAddr);

      			lockAddr[_newAddr] = lockAddr[oldAddr];

      			 
      			balance[_newAddr] = balance[oldAddr];
      			balance[oldAddr] = 0;

      			privateBalance[_newAddr] = privateBalance[oldAddr];
      			privateBalance[oldAddr] = 0;

      			emit Transfer(oldAddr, _newAddr, balance[_newAddr]);
      		}
      	}


      	return true;
      }
     
 
 
 
 
 

      function inTransfer(address _from, address _to,uint256 value) onlyOwners public{
      	require(allowControl[_from] == true);  
      	require(balance[_from] >= value);

      	balance[_from] -= value;
        balance[_to] = balance[_to].add(value);

        if(privateBalance[_from] <= value)
        {
        	privateBalance[_to] += privateBalance[_from];
        	privateBalance[_from] = 0;
        }
        else
        {
        	privateBalance[_from] = privateBalance[_from].sub(value);
        	privateBalance[_to] = privateBalance[_to].add(value);
        }

        emit Transfer(_from,_to,value); 
      }


     function balanceOfPrivate(address _walletAddress) public view returns (uint256){
        return privateBalance[_walletAddress]; 
     }

}





 
contract NateePrivate {
	
    function redeemToken(address _redeem, uint256 _value) external;
	function getMaxHolder() view external returns(uint256);
	function getAddressByID(uint256 _id) view external returns(address);
	function balancePrivate(address _walletAddress)  public view returns (uint256);
	
}

 
contract SGDSInterface{
  function balanceOf(address tokenOwner) public view returns (uint256 balance);
  function intTransfer(address _from, address _to, uint256 _value) external;
  function transferWallet(address _from,address _to) external;
  function getUserControl(address _addr) external view returns(bool);  
  function useSGDS(address useAddr,uint256 value) external returns(bool);
  function transfer(address _to, uint256 _value) public returns (bool);

}

 
contract NateeWarrantInterface {

	function balanceOf(address tokenOwner) public view returns (uint256 balance);
	function redeemWarrant(address _from, uint256 _value) external;
	function getWarrantInfo() external view returns(string name_,string symbol_,uint256 supply_ );
	function getUserControl(address _addr) external view returns(bool);
	function sendWarrant(address _to,uint256 _value) external;
	function expireDate() public pure returns (uint32);
}



 
 
 
 
 
 

 
contract Marketing is MyToken{
	struct REFERAL{
		uint8   refType;
		uint8   fixRate;  
		uint256 redeemCom;  
		uint256 allCommission;
		uint256 summaryInvest;
	}

	REFERAL[] referals;
	mapping (address => uint256) referToID;

 
	function addReferal(address _address,uint8 referType,uint8 rate) onlyOwners public{
		require(referToID[_address] == 0);
		uint256 idx = referals.push(REFERAL(referType,rate,0,0,0));
		referToID[_address] = idx;
	}


 
	function addCommission(address _address,uint256 buyToken) internal{
		uint256 idx;
		if(referToID[_address] > 0)
		{
			idx = referToID[_address] - 1;
			uint256 refType = uint256(referals[idx].refType);
			uint256 fixRate = uint256(referals[idx].fixRate);

			if(refType == 1 || refType == 3 || refType == 4){
				referals[idx].summaryInvest += buyToken;
				if(referals[idx].summaryInvest <= 80000){
					referals[idx].allCommission =  referals[idx].summaryInvest / 20 / 2;  
				}else if(referals[idx].summaryInvest >80000 && referals[idx].summaryInvest <=320000){
					referals[idx].allCommission = 2000 + (referals[idx].summaryInvest / 10 / 2);  
				}else if(referals[idx].summaryInvest > 320000){
					referals[idx].allCommission = 2000 + 12000 + (referals[idx].summaryInvest * 15 / 100 / 2);  
				}
			}
			else if(refType == 2 || refType == 5){
				referals[idx].summaryInvest += buyToken;
				referals[idx].allCommission = (referals[idx].summaryInvest * 100) * fixRate / 100 / 2;
			}
		}
	}

	function getReferByAddr(address _address) onlyOwners view public returns(uint8 refType,
																			 uint8 fixRate,
																			 uint256 commision,
																			 uint256 allCommission,
																			 uint256 summaryInvest){
		REFERAL memory refer = referals[referToID[_address]-1];

		refType = refer.refType;
		fixRate = refer.fixRate;
		commision = refer.redeemCom;
		allCommission = refer.allCommission;
		summaryInvest = refer.summaryInvest;

	}
 
	function checkHaveRefer(address _address) public view returns(bool){
		return (referToID[_address] > 0);
	}

 
	function getCommission(address addr) public view returns(uint256){
		require(referToID[addr] > 0);

		return referals[referToID[addr] - 1].allCommission;
	}
}

 
 
 
 
 
 

contract ICO_Token is  Marketing{

	uint256 PRE_ICO_ROUND = 20000000 ;
	uint256 ICO_ROUND = 40000000 ;
	uint256 TOKEN_PRICE = 50;  

	bool    startICO;   
	bool    icoPass;
	bool    hardCap;
	bool    public pauseICO;
	uint32  public icoEndTime;
	uint32  icoPauseTime;
	uint32  icoStartTime;
	uint256 totalSell;
	uint256 MIN_PRE_ICO_ROUND = 400 ;
	uint256 MIN_ICO_ROUND = 400 ;
	uint256 MAX_ICO_ROUND = 1000000 ;
	uint256 SOFT_CAP = 10000000 ;

	uint256 _1Token = 1 ether;

	SGDSInterface public sgds;
	NateeWarrantInterface public warrant;

	mapping (address => uint256) totalBuyICO;
	mapping (address => uint256) redeemed;
	mapping (address => uint256) redeemPercent;
	mapping (address => uint256) redeemMax;


	event StartICO(address indexed admin, uint32 startTime,uint32 endTime);
	event PassSoftCap(uint32 passTime);
	event BuyICO(address indexed addr_,uint256 value);
	event BonusWarrant(address indexed,uint256 startRank,uint256 stopRank,uint256 warrantGot);

	event RedeemCommision(address indexed, uint256 sgdsValue,uint256 curCom);
	event Refund(address indexed,uint256 sgds,uint256 totalBuy);

	constructor() public {
		 
		 
		pauseICO = false;
		icoEndTime = uint32(now + 365 days); 
	}

	function pauseSellICO() onlyOwners external{
		require(startICO == true);
		require(pauseICO == false);
		icoPauseTime = uint32(now);
		pauseICO = true;

	}
 
	function resumeSellICO() onlyOwners external{
		require(pauseICO == true);
		pauseICO = false;
		 
		uint32   pauseTime = uint32(now) - icoPauseTime;
		uint32   maxSellTime = icoStartTime + 730 days;
		icoEndTime += pauseTime;
		if(icoEndTime > maxSellTime) icoEndTime = maxSellTime;
		pauseICO = false;
	}

 
 

	function startSellICO() internal returns(bool){
		require(startICO == false);  
		icoStartTime = uint32(now);
		icoEndTime = uint32(now + 270 days);  
		startICO = true;

		emit StartICO(msg.sender,icoStartTime,icoEndTime);

		return true;
	}

 
 
 
 
 
 
	function passSoftCap() internal returns(bool){
		icoPass = true;
		 
		if(icoEndTime - uint32(now) > 90 days)
		{
			icoEndTime = uint32(now) + 90 days;
		}


		emit PassSoftCap(uint32(now));
	}

 
 

	function refund() public{
		require(icoPass == false);
		uint32   maxSellTime = icoStartTime + 730 days;
		if(pauseICO == true)
		{
			if(uint32(now) <= maxSellTime)
			{
				return;
			}
		}
		if(uint32(now) >= icoEndTime)
		{
			if(totalBuyICO[msg.sender] > 0) 
			{
				uint256  totalSGDS = totalBuyICO[msg.sender] * TOKEN_PRICE;
				uint256  totalNatee = totalBuyICO[msg.sender] * _1Token;
				require(totalNatee == balance[msg.sender]);

				emit Refund(msg.sender,totalSGDS,totalBuyICO[msg.sender]);
				totalBuyICO[msg.sender] = 0;
				sgds.transfer(msg.sender,totalSGDS);
			}	
		}
	}

 
 
 

	function userSetAllowControl(bool allow) public{
		require(closeICO == true);
		allowControl[msg.sender] = allow;
	}
	
 

	function bonusWarrant(address _addr,uint256 buyToken) internal{
	 
	 
	 
	 
	 
		uint256  gotWarrant;

 
		if(totalSell <= 4000000)
			gotWarrant = buyToken / 2;   
		else if(totalSell >= 4000001 && totalSell <= 12000000)
		{
			if(totalSell - buyToken < 4000000)  
			{
				gotWarrant = (4000000 - (totalSell - buyToken)) / 2;
				gotWarrant += (totalSell - 4000000) * 40 / 100;
			}
			else
			{
				gotWarrant = buyToken * 40 / 100; 
			}
		}
		else if(totalSell >= 12000001 && totalSell <= 20000000)
		{
			if(totalSell - buyToken < 4000000)
			{
				gotWarrant = (4000000 - (totalSell - buyToken)) / 2;
				gotWarrant += 2400000;  
				gotWarrant += (totalSell - 12000000) * 30 / 100; 
			}
			else if(totalSell - buyToken < 12000000 )
			{
				gotWarrant = (12000000 - (totalSell - buyToken)) * 40 / 100;
				gotWarrant += (totalSell - 12000000) * 30 / 100; 				
			}
			else
			{
				gotWarrant = buyToken * 30 / 100; 
			}
		}
		else if(totalSell >= 20000001 && totalSell <= 30000000)  
		{
			gotWarrant = buyToken / 5;  
		}
		else if(totalSell >= 30000001 && totalSell <= 40000000)
		{
			if(totalSell - buyToken < 30000000)
			{
				gotWarrant = (30000000 - (totalSell - buyToken)) / 5;
				gotWarrant += (totalSell - 30000000) / 10;
			}
			else
			{
				gotWarrant = buyToken / 10;   
			}
		}
		else if(totalSell >= 40000001)
		{
			if(totalSell - buyToken < 40000000)
			{
				gotWarrant = (40000000 - (totalSell - buyToken)) / 10;
			}
			else
				gotWarrant = 0;
		}

 

		if(gotWarrant > 0)
		{
			gotWarrant = gotWarrant * _1Token;
			warrant.sendWarrant(_addr,gotWarrant);
			emit BonusWarrant(_addr,totalSell - buyToken,totalSell,gotWarrant);
		}

	}

 
 
 

	function buyNateeToken(address _addr, uint256 value,bool refer) onlyOwners external returns(bool){
		
		require(closeICO == false);
		require(pauseICO == false);
		require(uint32(now) <= icoEndTime);
		require(value % 2 == 0);  

		if(startICO == false) startSellICO();
		uint256  sgdWant;
		uint256  buyToken = value;

		if(totalSell < PRE_ICO_ROUND)    
		{
			require(buyToken >= MIN_PRE_ICO_ROUND);

			if(buyToken > PRE_ICO_ROUND - totalSell)
			   buyToken = uint256(PRE_ICO_ROUND - totalSell);
		}
		else if(totalSell < PRE_ICO_ROUND + ICO_ROUND)
		{
			require(buyToken >= MIN_ICO_ROUND);

			if(buyToken > MAX_ICO_ROUND) buyToken = MAX_ICO_ROUND;
			if(buyToken > (PRE_ICO_ROUND + ICO_ROUND) - totalSell)
				buyToken = (PRE_ICO_ROUND + ICO_ROUND) - totalSell;
		}
		
		sgdWant = buyToken * TOKEN_PRICE;

		require(sgds.balanceOf(_addr) >= sgdWant);
		sgds.intTransfer(_addr,address(this),sgdWant);  
		emit BuyICO(_addr, buyToken * _1Token);

		balance[_addr] += buyToken * _1Token;
		totalBuyICO[_addr] += buyToken;
		 
		 
		totalSupply_ += buyToken * _1Token;
		 
		totalSell += buyToken;
		if(totalBuyICO[_addr] >= 8000 && referToID[_addr] == 0)
			addReferal(_addr,1,0);

		bonusWarrant(_addr,buyToken);
		if(totalSell >= SOFT_CAP && icoPass == false) passSoftCap();  

		if(totalSell >= PRE_ICO_ROUND + ICO_ROUND && hardCap == false)
		{
			hardCap = true;
			setCloseICO();
		}
		
		setAllowControl(_addr);
		addHolder(_addr);

		if(refer == true)
			addCommission(_addr,buyToken);

		emit Transfer(address(this),_addr, buyToken * _1Token);


		return true;
	}


 
 
	
	function redeemCommision(address addr,uint256 value) public{
		require(referToID[addr] > 0);
		uint256 idx = referToID[addr] - 1;
		uint256 refType = uint256(referals[idx].refType);

		if(refType == 1 || refType == 2 || refType == 3)
			require(icoPass == true);

		require(value > 0);
		require(value <= referals[idx].allCommission - referals[idx].redeemCom);

		 
		referals[idx].redeemCom += value; 
		sgds.transfer(addr,value);

		emit RedeemCommision(addr,value,referals[idx].allCommission - referals[idx].redeemCom);

	}


 
	function getTotalSell() external view returns(uint256){
		return totalSell;
	}
 
	function getTotalBuyICO(address _addr) external view returns(uint256){
		return totalBuyICO[_addr];
	}


 
 
	function addCOPartner(address addr,uint256 percent,uint256 maxFund) onlyOwners public {
			require(redeemPercent[addr] == 0);
			redeemPercent[addr] = percent;
			redeemMax[addr] = maxFund;

	}

	function redeemFund(address addr,uint256 value) public {
		require(icoPass == true);
		require(redeemPercent[addr] > 0);
		uint256 maxRedeem;

		maxRedeem = (totalSell * TOKEN_PRICE) * redeemPercent[addr] / 10000;  
		if(maxRedeem > redeemMax[addr]) maxRedeem = redeemMax[addr];

		require(redeemed[addr] + value <= maxRedeem);

		sgds.transfer(addr,value);
		redeemed[addr] += value;

	}

	function checkRedeemFund(address addr) public view returns (uint256) {
		uint256 maxRedeem;

		maxRedeem = (totalSell * TOKEN_PRICE) * redeemPercent[addr] / 10000;  
		if(maxRedeem > redeemMax[addr]) maxRedeem = redeemMax[addr];
		
		return maxRedeem - redeemed[addr];

	}

 

	function setCloseICO() public {
		require(closeICO == false);
		require(startICO == true);
		require(icoPass == true);

		if(hardCap == false){
			require(uint32(now) >= icoEndTime);
		}



		uint256 lessAdvisor;
		uint256 maxAdvisor;
		uint256 maxFounder;
		uint256 i;
		closeICO = true;

		 
		maxAdvisor = 0;
		for(i=0;i<advisors.length;i++)
		{
			if(advisors[i] != address(0)) 
				maxAdvisor++;
		}

		maxFounder = 0;
		for(i=0;i<founders.length;i++)
		{
			if(founders[i] != address(0))
				maxFounder++;
		}

		TOKEN_PER_ADVISOR = ADVISOR_SUPPLY / maxAdvisor;

		 
		if(TOKEN_PER_ADVISOR > 200000 ether) { 
			TOKEN_PER_ADVISOR = 200000 ether;
		}

		lessAdvisor = ADVISOR_SUPPLY - (TOKEN_PER_ADVISOR * maxAdvisor);
		 

		TOKEN_PER_FOUNDER = (FOUNDER_SUPPLY + lessAdvisor) / maxFounder;
		emit CloseICO();

		 
		for(i=0;i<advisors.length;i++)
		{
			if(advisors[i] != address(0))
			{
				balance[advisors[i]] += TOKEN_PER_ADVISOR;
				totalSupply_ += TOKEN_PER_ADVISOR;

				lockAddress(advisors[i]);  
				addHolder(advisors[i]);
				setAllowControl(advisors[i]);
				emit Transfer(address(this), advisors[i], TOKEN_PER_ADVISOR);
				emit RedeemAdvisor(advisors[i],TOKEN_PER_ADVISOR);

			}
		}

		for(i=0;i<founders.length;i++)
		{
			if(founders[i] != address(0))
			{
				balance[founders[i]] += TOKEN_PER_FOUNDER;
				totalSupply_ += TOKEN_PER_FOUNDER;

				lockAddress(founders[i]);
				addHolder(founders[i]);
				setAllowControl(founders[i]);
				emit Transfer(address(this),founders[i],TOKEN_PER_FOUNDER);
				emit RedeemFounder(founders[i],TOKEN_PER_FOUNDER);

			}
		}

	}

} 


 
 
 
 
 


contract NATEE is ICO_Token {
	using SafeMath256 for uint256;
	string public name = "NATEE";
	string public symbol = "NATEE";  
	uint256 public decimals = 18;
	
	uint256 public INITIAL_SUPPLY = 100000000 ether;
	
	NateePrivate   public nateePrivate;
	bool privateRedeem;
	uint256 public nateeWExcRate = 100;  
	uint256 public nateeWExcRateExp = 100;  
    address public AGC_ADDR;
    address public RM_PRIVATE_INVESTOR_ADDR;
    address public ICZ_ADDR;
    address public SEITEE_INTERNAL_USE;

	event RedeemNatee(address indexed _addr, uint256 _private,uint256 _gotNatee);
	event RedeemWarrat(address indexed _addr,address _warrant,string symbole,uint256 value);

	constructor() public {

		AGC_ADDR = 0xdd25648927291130CBE3f3716A7408182F28b80a;  
		addCOPartner(AGC_ADDR,100,30000000);
		RM_PRIVATE_INVESTOR_ADDR = 0x32F359dE611CFe8f8974606633d8bDCBb33D91CB;
	 
		ICZ_ADDR = 0x1F10C47A07BAc12eDe10270bCe1471bcfCEd4Baf;  
		addCOPartner(ICZ_ADDR,500,20000000);
		 
		SEITEE_INTERNAL_USE = 0x1219058023bE74FA30C663c4aE135E75019464b4;

		balance[RM_PRIVATE_INVESTOR_ADDR] = 3000000 ether;
		totalSupply_ += 3000000 ether;
		lockAddress(RM_PRIVATE_INVESTOR_ADDR);
		setAllowControl(RM_PRIVATE_INVESTOR_ADDR);
		addHolder(RM_PRIVATE_INVESTOR_ADDR);
		emit Transfer(address(this),RM_PRIVATE_INVESTOR_ADDR,3000000 ether);


		balance[SEITEE_INTERNAL_USE] = 20000000 ether;
		totalSupply_ += 20000000 ether;
		setAllowControl(SEITEE_INTERNAL_USE);
		addHolder(SEITEE_INTERNAL_USE);
		emit Transfer(address(this),SEITEE_INTERNAL_USE,20000000 ether);


		sgds = SGDSInterface(0xf7EfaF88B380469084f3018271A49fF743899C89);
		warrant = NateeWarrantInterface(0x7F28D94D8dc94809a3f13e6a6e9d56ad0B6708fe);
		nateePrivate = NateePrivate(0x67A9d6d1521E02eCfb4a4C110C673e2c027ec102);

	}

 
	function setSGDSContractAddress(address _addr) onlyOwners external {
		sgds = SGDSInterface(_addr);
	}

    function setNateePrivate(address _addr)	onlyOwners external {
        nateePrivate = NateePrivate(_addr);
    }

    function setNateeWarrant(address _addr) onlyOwners external {
    	warrant = NateeWarrantInterface(_addr);
    }

    function changeWarrantPrice(uint256 normalPrice,uint256 expPrice) onlyOwners external{
    	if(uint32(now) < warrant.expireDate())
    	{
    		nateeWExcRate = normalPrice;
    		nateeWExcRateExp = expPrice;
    	}
    }
    

 

	function redeemWarrant(address addr,uint256 value) public returns(bool){
		require(owners[msg.sender] == true || addr == msg.sender);
		require(closeICO == true);
		require(sgds.getUserControl(addr) == false);

		uint256 sgdsPerToken; 
		uint256 totalSGDSUse;
		uint256 wRedeem;
		uint256 nateeGot;

		require(warrant.getUserControl(addr) == false);

		if( uint32(now) <= warrant.expireDate())
			sgdsPerToken = nateeWExcRate;
		else
			sgdsPerToken = nateeWExcRateExp;

		wRedeem = value / _1Token; 
		require(wRedeem > 0); 
		totalSGDSUse = wRedeem * sgdsPerToken;

		 
		require(sgds.balanceOf(addr) >= totalSGDSUse);
		 
		if(sgds.useSGDS(addr,totalSGDSUse) == true) 
		{
			nateeGot = wRedeem * _1Token;
			warrant.redeemWarrant(addr,nateeGot);  

			balance[addr] += nateeGot;
			 
			 
			 
			totalSupply_ += nateeGot;
			 

			addHolder(addr);
			emit Transfer(address(this),addr,nateeGot);
			emit RedeemWarrat(addr,address(warrant),"NATEE-W1",nateeGot);
		}

		return true;

	}


 
	function reddemAllPrivate() onlyOwners public returns(bool){

		require(privateRedeem == false);

        uint256 maxHolder = nateePrivate.getMaxHolder();
        address tempAddr;
        uint256 priToken;
        uint256  nateeGot;
        uint256 i;
        for(i=0;i<maxHolder;i++)
        {
            tempAddr = nateePrivate.getAddressByID(i);
            priToken = nateePrivate.balancePrivate(tempAddr);
            if(priToken > 0)
            {
            nateeGot = priToken * 8;
            nateePrivate.redeemToken(tempAddr,priToken);
            balance[tempAddr] += nateeGot;
            totalSupply_ += nateeGot;
            privateBalance[tempAddr] += nateeGot;
            allowControl[tempAddr] = true;

            addHolder(tempAddr);
            emit Transfer( address(this), tempAddr, nateeGot);
            emit RedeemNatee(tempAddr,priToken,nateeGot);
            }
        }

        privateRedeem = true;
    }

}