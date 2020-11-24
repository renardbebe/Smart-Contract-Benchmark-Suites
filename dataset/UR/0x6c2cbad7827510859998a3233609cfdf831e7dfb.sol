 

pragma solidity ^0.4.15;


contract Contributor {

     
    bool isInitiated = false;

     
    address creatorAddress;

    address contributorAddress;

    address marketplaceAddress;

     
    string name;

    uint creationTime;

    bool isRepudiated = false;

     
    enum ExtensionType {MODULE, THEME}
    struct Extension {
    string name;
    string version;
    ExtensionType extType;
    string moduleKey;
    }

    mapping (string => Extension) private publications;

     
    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

     
    event newExtensionPublished (string _name, string _hash, string _version, ExtensionType _type, string _moduleKey);

     
     
    function Contributor(string _name, address _contributorAddress, address _marketplaceAddress) {
        creatorAddress = msg.sender;
        contributorAddress = _contributorAddress;
        marketplaceAddress = _marketplaceAddress;
        creationTime = now;
        name = _name;
        isInitiated = true;
    }

     
    function publishExtension(string _hash, string _name, string _version, ExtensionType _type, string _moduleKey)
    onlyBy(creatorAddress) {
        publications[_hash] = Extension(_name, _version, _type, _moduleKey);
        newExtensionPublished(_name, _hash, _version, _type, _moduleKey);
    }

     
     
    function getInitiated() constant returns (bool) {
        return isInitiated;
    }

     
    function getInfos() constant returns (address, string, uint) {
        return (creatorAddress, name, creationTime);
    }

     
    function getExtensionPublication(string _hash) constant returns (string, string, ExtensionType) {
        return (publications[_hash].name, publications[_hash].version, publications[_hash].extType);
    }

    function haveExtension(string _hash) constant returns (bool) {
        bool result = true;

        if (bytes(publications[_hash].name).length == 0) {
            result = false;
        }
        return result;
    }
}