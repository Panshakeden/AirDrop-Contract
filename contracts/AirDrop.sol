// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// import {VRFCoordinatorV2Interface} from "@chainlink/contracts@0.8.0/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts@0.8.0/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract AirDrop is VRFConsumerBaseV2{
    
    uint256 contentPerCount;
    address owner;
    uint256 submissionStart;
    uint256 submissionEnd;
    IERC20 public token;
    address[] public registeredUsers;

        event WinnerSelected(address indexed winnerAddress);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);


      struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    /**
     * HARDCODED FOR MUMBAI
     * COORDINATOR: 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
     */

 struct User{
    uint256 TotalEntries;
    mapping (string=>bool) ContentSubmission;
 }   

mapping (address=>User) public users; 
mapping (address=>bool) hasRegistered;

// constructor(uint256 _requiredEntries,uint256 _prizeAmount){
//     owner= msg.sender;
//     contentPerCount=0;
//     submissionStart= 60;
//     submissionEnd= block.timestamp + submissionStart;
//      requiredEntries = _requiredEntries;
//     prizeAmount = _prizeAmount;
// }


 constructor(
        uint64 subscriptionId,
        IERC20 _token
        // uint256 _requiredEntries,uint256 _prizeAmount
    )
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
        // ConfirmedOwner(msg.sender)
    {
     token=IERC20(_token);
     owner= msg.sender;
    contentPerCount=0;
    submissionStart= 60;
    submissionEnd= block.timestamp + submissionStart;



        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = subscriptionId;
    }


function Register() external {
     require(!hasRegistered[msg.sender], "User registered already");
    registeredUsers.push(msg.sender);
     hasRegistered[msg.sender]=true;
}

function Login()external {
    require(hasRegistered[msg.sender],"Go and register");
     hasRegistered[msg.sender]=true;
}

function SubmitContent(string memory _Content)external {
    require(block.timestamp < submissionEnd, "Submission has ended");
    require(hasRegistered[msg.sender], "User not registered");
    require(!users[msg.sender].ContentSubmission[_Content],"content already submitted");

    users[msg.sender].TotalEntries += contentPerCount;
    users[msg.sender].ContentSubmission[_Content]=true;

}

 function setEntryPerContent(uint256 _entryPerContent) external {
        OnlyOwner();
        contentPerCount = _entryPerContent;
    }

    function OnlyOwner()private view  {
        require(owner==msg.sender," you are not the owner");
    }

    function getTotalEntries(address _users) external view returns (uint256) {
        return users[_users].TotalEntries;
    }


     // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        internal
        // onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }


      function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }


     function selectWinner() external {
        // Ensure that there are enough participants
        require(registeredUsers.length >= 3, "There must be at least 3 participants.");

        // Generate a random number
        uint256 randomNumber = requestRandomWords();

        // Calculate the index of the winner using the random number
        uint256 index = randomNumber % registeredUsers.length;

        // Get the address of the winner from the participants array
        address winnerAddress = registeredUsers[index];
        emit WinnerSelected(winnerAddress);
    }


}

