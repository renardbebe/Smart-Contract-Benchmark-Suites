 

pragma solidity ^0.4.24;

contract LIMITED_42 {

    struct PatternOBJ {
        address owner;
        string message;
        string data;
    }

    mapping(address => bytes32[]) public Patterns;
    mapping(bytes32 => PatternOBJ) public Pattern;

    string public info = "";

    address private constant emergency_admin = 0x59ab67D9BA5a748591bB79Ce223606A8C2892E6d;
    address private constant first_admin = 0x9a203e2E251849a26566EBF94043D74FEeb0011c;
    address private admin = 0x9a203e2E251849a26566EBF94043D74FEeb0011c;


     

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

     

    function checkPatternExistance (bytes32 patternid) public view
    returns(bool)
    {
      if(Pattern[patternid].owner == address(0)){
        return false;
      }else{
        return true;
      }
    }

    function createPattern(bytes32 patternid, string dataMixed, address newowner, string message)
        onlyAdmin
        public
        returns(string)
    {
       
      string memory data = toUpper(dataMixed);

       
      require(keccak256(abi.encodePacked(data)) == patternid);

       
      require(newowner != address(0));

       
      if(Pattern[patternid].owner == address(0)){
           

           
          Pattern[patternid].owner = newowner;
          Pattern[patternid].message = message;
          Pattern[patternid].data = data;

          addPatternUserIndex(newowner,patternid);

          return "ok";

      }else{
           
          return "error:exists";
      }

    }
    function transferPattern(bytes32 patternid,address newowner,string message, uint8 v, bytes32 r, bytes32 s)
      public
      returns(string)
    {
       
      address oldowner = admin;

       
      require(Pattern[patternid].owner != address(0));

       
      require(newowner != address(0));

       
      if(Pattern[patternid].owner == msg.sender){
         
        oldowner = msg.sender;
      }else{
         

         
        bytes32 h = prefixedHash2(newowner);
         
        require(ecrecover(h, v, r, s) == Pattern[patternid].owner);
        oldowner = Pattern[patternid].owner;
      }

       
      removePatternUserIndex(oldowner,patternid);

       
      Pattern[patternid].owner = newowner;
      Pattern[patternid].message = message;
       
      addPatternUserIndex(newowner,patternid);

      return "ok";

    }

    function changeMessage(bytes32 patternid,string message, uint8 v, bytes32 r, bytes32 s)
      public
      returns(string)
    {
       
      address owner = admin;

       
      require(Pattern[patternid].owner != address(0));

       
      if(Pattern[patternid].owner == msg.sender){
         
        owner = msg.sender;
      }else{
         

         
        bytes32 h = prefixedHash(message);
        owner = ecrecover(h, v, r, s);
      }

      require(Pattern[patternid].owner == owner);

      Pattern[patternid].message = message;

      return "ok";

    }

    function verifyOwner(bytes32 patternid, address owner, uint8 v, bytes32 r, bytes32 s)
      public
      view
      returns(bool)
    {
       
      require(Pattern[patternid].owner != address(0));

       
      bytes32 h = prefixedHash2(owner);
      address owner2 = ecrecover(h, v, r, s);

      require(owner2 == owner);

       
      if(Pattern[patternid].owner == owner2){
        return true;
      }else{
        return false;
      }
    }

    function prefixedHash(string message)
      private
      pure
      returns (bytes32)
    {
        bytes32 h = keccak256(abi.encodePacked(message));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function prefixedHash2(address message)
      private
      pure
      returns (bytes32)
    {
        bytes32 h = keccak256(abi.encodePacked(message));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }


    function addPatternUserIndex(address account, bytes32 patternid)
      private
    {
        Patterns[account].push(patternid);
    }

    function removePatternUserIndex(address account, bytes32 patternid)
      private
    {
      require(Pattern[patternid].owner == account);
      for (uint i = 0; i<Patterns[account].length; i++){
          if(Patterns[account][i] == patternid){
               
              Patterns[account][i] = Patterns[account][Patterns[account].length-1];
               
              delete Patterns[account][Patterns[account].length-1];
               
              Patterns[account].length--;
          }
      }
    }

    function userHasPattern(address account)
      public
      view
      returns(bool)
    {
      if(Patterns[account].length >=1 )
      {
        return true;
      }else{
        return false;
      }
    }

    function emergency(address newa, uint8 v, bytes32 r, bytes32 s, uint8 v2, bytes32 r2, bytes32 s2)
      public
    {
       
      bytes32 h = prefixedHash2(newa);

       
      require(ecrecover(h, v, r, s)==admin);
      require(ecrecover(h, v2, r2, s2)==emergency_admin);
       
      admin = newa;
    }

    function changeInfo(string newinfo)
      public
      onlyAdmin
    {
       
       

      info = newinfo;
    }


    function toUpper(string str)
      pure
      private
      returns (string)
    {
      bytes memory bStr = bytes(str);
      bytes memory bLower = new bytes(bStr.length);
      for (uint i = 0; i < bStr.length; i++) {
         
        if ((bStr[i] >= 65+32) && (bStr[i] <= 90+32)) {
           
          bLower[i] = bytes1(int(bStr[i]) - 32);
        } else {
          bLower[i] = bStr[i];
        }
      }
      return string(bLower);
    }

}