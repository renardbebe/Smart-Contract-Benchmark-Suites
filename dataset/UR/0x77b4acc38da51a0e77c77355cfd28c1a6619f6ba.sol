 

pragma solidity ^0.5.0;

contract Adventure {
     

    event Situation(uint indexed id, string situationText, bytes32[] choiceTexts);


     
    mapping(uint => mapping(uint => uint)) links;
     
    mapping(uint => uint) options;

     
    mapping(uint => address) authors;
     
    mapping(address => string) signatures;

     
    uint situationCount;
     
    uint pathwayCount;



    constructor(string memory situationText, bytes32[] memory choiceTexts) public {
        require(choiceTexts.length > 0,"choices");

         
        options[0] = choiceTexts.length;

         
        pathwayCount = choiceTexts.length;

         
        authors[0] = msg.sender;

        emit Situation(0,situationText,choiceTexts);
    }

    function add_situation(
        uint fromSituation,
        uint fromChoice,
        string memory situationText,
        bytes32[] memory choiceTexts) public{
         
        require(pathwayCount + choiceTexts.length > 1, "pathwayCount");

         
        require(bytes(situationText).length > 0,"situation");

         
        require(fromChoice < options[fromSituation],"options");

         
        require(links[fromSituation][fromChoice] == 0,"choice");

        for(uint i = 0; i < choiceTexts.length; i++){
            require(choiceTexts[i].length > 0,"choiceLength");
        }

         
        situationCount++;

         
        pathwayCount += choiceTexts.length - 1;

         
        links[fromSituation][fromChoice] = situationCount;

         
        options[situationCount] = choiceTexts.length;

         
        authors[situationCount] = msg.sender;

        emit Situation(situationCount,situationText,choiceTexts);

    }

    function add_signature(string memory signature) public{
        signatures[msg.sender] = signature;
    }

    function get_signature(uint situation) public view returns(string memory){
        return signatures[authors[situation]];
    }
    function get_author(uint situation) public view returns(address){
        return authors[situation];
    }

    function get_pathwayCount() public view returns(uint){
        return pathwayCount;
    }

    function get_next_situation(uint fromSituation, uint fromChoice) public view returns(uint){
        return links[fromSituation][fromChoice];
    }
}