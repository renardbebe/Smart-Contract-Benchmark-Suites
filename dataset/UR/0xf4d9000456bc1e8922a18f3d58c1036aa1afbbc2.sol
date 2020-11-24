 

pragma solidity ^0.4.24;

 
library Address {

   
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

 
library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

 
contract ERC165 is IERC165 {

    bytes4 private constant _InterfaceId_ERC165 = 0x80ac58cd;
   

   
    mapping(bytes4 => bool) private _supportedInterfaces;

   
    constructor() public
    {
        _registerInterface(_InterfaceId_ERC165);
    }

   
    function supportsInterface(bytes4 interfaceId) external view
    returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

   
    function _registerInterface(bytes4 interfaceId) internal
    {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 
contract IERC721Receiver {
   
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    )
    public
        returns(bytes4);
}

 
contract IERC721 is IERC165 {

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external payable;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes data
        ) external payable;
}

 
contract ERC721 is ERC165, IERC721 {

    using SafeMath for uint256;
    using Address for address;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => uint256) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
     

    constructor() public
    {
     
        _registerInterface(_InterfaceId_ERC721);
    }

     
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

   
    function ownerOf(uint256 tokenId) external view returns (address) {
        _ownerOf(tokenId);
    }
  
    function _ownerOf(uint256 tokenId) internal view returns (address owner) {
        owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function approve(address to, uint256 tokenId) external payable {
        address owner = _tokenOwner[tokenId];
        require(to != owner);
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender]);

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) external view returns (address) {
        _getApproved(tokenId);
    }
  
    function _getApproved(uint256 tokenId) internal view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }
     
    function setApprovalForAll(address to, bool approved) external {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(
        address owner,
        address operator
    )
        external
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external payable
    {
        _transferFrom(from, to, tokenId);
    }
    
    function _transferFrom(
        address from, 
        address to,
        uint256 tokenId) internal {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(to != address(0));
        
        _clearApproval(from, tokenId);
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);
        
        emit Transfer(from, to, tokenId);
    }

     
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external payable
    {
         
        _safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes _data
    )
        external payable
    {
        _safeTransferFrom(from, to, tokenId, _data);
    }
    
    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes _data)
        internal
    {
        _transferFrom(from, to, tokenId);
         
        require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = _tokenOwner[tokenId];
         
         
         
        return (
        spender == owner ||
        _getApproved(tokenId) == spender ||
        _operatorApprovals[owner][spender]
        );
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        _clearApproval(owner, tokenId);
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

     
    function _clearApproval(address owner, uint256 tokenId) internal {
        require(_ownerOf(tokenId) == owner);
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }

     
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }

     
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(_ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }

     
    function _checkAndCallSafeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes _data
    )
        internal
        returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721Receiver(to).onERC721Received(
        msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
}

contract Bloccelerator is ERC721 {
    
    mapping (uint256 => string) public Courses;
    
       
    struct Certificate {
        string name;
        uint256 courseID;
        uint256 date;
        bytes32 registrationCode;
    }

   

     
    event Creation(uint256 indexed c_id, string indexed c_name, string indexed c_course);
    
     
    mapping (uint256 => Certificate) private participants;
    mapping (bytes32 => uint256[]) private studentDetail;

     
    uint256[] private certificates;
    uint256[] private courseIDs;
    address private owner;
    string public constant name = "Bloccelerator";
    string public constant symbol = "BLOC";
  
    constructor()
    public
    {
        owner = msg.sender;
    }
  
    modifier onlyContractOwner {
        require(msg.sender == owner);
        _;
    }
    
     
    function create(address _to, string _name, uint256 _course, uint256 _date, bytes32 _userCode) 
    public
    onlyContractOwner
    returns (uint256 certificateID)  {
        certificateID = certificates.length;
        certificates.push(certificateID);
        super._mint(_to, certificateID);
        participants[certificateID] = Certificate({
            name: _name,
            courseID: _course,
            date: _date,
            registrationCode: _userCode
        });
        studentDetail[_userCode].push(certificateID);
        
        emit Creation(certificateID, _name, Courses[_course]);
    }
  
    function addCourse(string _name) public onlyContractOwner returns (uint256 courseID) {
        require(verifyCourseExists(_name) != true);
        uint _courseCount = courseIDs.length;
        courseIDs.push(_courseCount);
        Courses[_courseCount] = _name;
        return _courseCount;
    }
  
    function verifyCourseExists(string _name) internal view returns (bool exists) {
        uint numberofCourses = courseIDs.length;
        for (uint i=0; i<numberofCourses; i++) {
            if (keccak256(abi.encodePacked(Courses[i])) == keccak256(abi.encodePacked(_name)))
            {
                return true;
            }
        }
        return false;
    }
  
    function getMyCertIDs(string IDNumber) public view returns (string _name, uint[] _certIDs) {
        bytes32 hashedID = keccak256(abi.encodePacked(IDNumber));
        uint[] storage ownedCerts = studentDetail[hashedID];
        require(verifyOwner(ownedCerts));
        
        _certIDs = studentDetail[hashedID];      
        _name = participants[_certIDs[0]].name;
    }
  
    function getCertInfo(uint256 certificateNumber) public view returns (string _name, string _courseName, uint256 _issueDate) {
        _name = participants[certificateNumber].name;
        _courseName = Courses[participants[certificateNumber].courseID];
        _issueDate = participants[certificateNumber].date;
    }
  
    function verifyOwner(uint[] _certIDs) internal view returns (bool isOwner) {
        uint _numberOfCerts = _certIDs.length;
        bool allCorrect = false;
        for (uint i=0; i<_numberOfCerts; i++) {
            allCorrect = (true && (_ownerOf(_certIDs[i]) == msg.sender));
        }
        return allCorrect;
    }
}