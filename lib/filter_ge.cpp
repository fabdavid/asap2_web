#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <boost/algorithm/string.hpp>
#include <boost/filesystem.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <sstream>
#include <cmath>
/*
#define UPFILE TEXT("filtered_up.json")
#define DOWNFILE TEXT("filtered_down.json")
*/

// TO COMPILE: g++ -o filter_ge filter_ge.cpp -lboost_system -lboost_filesystem -std=c++11

using namespace std;
using namespace boost::algorithm;
using namespace boost::filesystem;

std::string join_vector(std::vector<int> v){
  
  std::stringstream ss;
  for(size_t i = 0; i < v.size(); ++i)
    {
      if(i != 0)
	ss << ",";
      ss << v[i];
    }
  std::string s = ss.str();
  return s;
}


double sciToDub(const string& str) {
  
  stringstream ss(str);
  double d = 0;
  ss >> d;

  /*  if (ss.fail()) {
    string s = "Unable to format ";
    s += str;
    s += " as a number!";
    throw (s);
  }
  */
  return (d);
}

string pathAppend(const string& p1, const string& p2) {
  
  char sep = '/';
  string tmp = p1;
  
#ifdef _WIN32
  sep = '\\';
#endif
  
  if (p1[p1.length()] != sep) { // Need to add a
    tmp += sep;                // path separator
    return(tmp + p2);
  }
  else
    return(p1 + p2);
}

// usage: filter_de PROJECT_PATH FDR_CUTOFF LOG_FC_CUTOFF MODE USER_ID RUN_ID

int main(int argc, char** argv) {
  string project_filepath = argv[1];
  string fdr_cutoff = argv[2];
  //  string fc_cutoff = argv[3];
  //  double logfc_cutoff = log2(sciToDub(fc_cutoff));

  string mode = argv[3];
  string user_id = argv[4];
  string run_id = argv[5];

  path project_path (project_filepath);
  path ge_path = project_path / "ge";
  path input_filepath = ge_path / run_id / "output.json";
  path dir = ge_path / run_id; //p.parent_path();
  path tmp_dir =  project_path / "tmp";
  
  path filtered_stats_path;
  if (mode == "ge_results"){
    filtered_stats_path = tmp_dir / (user_id + "_ge_filtered_stats.txt");
  }

  std::ifstream fin(input_filepath.c_str());

  // Check if the input file stream is opened successfully
  if (!fin.is_open()) {
    std::cerr << "Failed to open input file: " << input_filepath.c_str() << std::endl;
    return 1;
  }
  
  std::string line;
  std::vector <int> vec_down;
  std::vector <int> vec_up;

  // Create an empty property tree object
  boost::property_tree::ptree pt;

  try {
    // Load the JSON file into the property tree
    boost::property_tree::read_json(input_filepath.c_str(), pt);

    // Accessing 'up' entries and performing test on the FDR value
    std::cout << "Up entries with FDR < threshold:" << std::endl;
    int i=0;
    for (const auto& up_entry : pt.get_child("up")) {
      /*      double fdr = up_entry.second.get<double>(3); //up_entry.second.front().second.data()); 
      std::string fdr_str = std::to_string(fdr);
      //      double fdr = up_entry.second.get<double>(3); // Index 3 corresponds to the FDR value
      */
      auto it = up_entry.second.begin();
      std::advance(it, 3); // Move iterator to the fourth element
      double fdr = std::stod(it->second.data());
      //cout << fdr_str << std::endl;
      if (fdr <= sciToDub(fdr_cutoff)) {
	/*	for (const auto& value : up_entry.second) {
	  //	  std::cout << value.second.get_value<std::string>() << " ";
	}
	std::cout << std::endl;
	*/
	vec_up.push_back(i);
      }
      i++;
    }

    // Accessing 'down' entries and performing test on the FDR value
    std::cout << "Down entries with FDR < 0.05:" << std::endl;
    i=0; 
    for (const auto& down_entry : pt.get_child("down")) {
      //      double fdr = sciToDub(down_entry.second.front().second.data());
      //      double fdr = down_entry.second.get<double>(3); // Index 3 corresponds to the FDR value
      auto it = down_entry.second.begin();
      std::advance(it, 3); // Move iterator to the fourth element                                                
      double fdr = std::stod(it->second.data());

      if (fdr <= sciToDub(fdr_cutoff)) {
	/*for (const auto& value : down_entry.second) {
	  std::cout << value.second.get_value<std::string>() << " ";
	  }
	  std::cout << std::endl;
	*/
	vec_down.push_back(i);
      }
      i++;
    }
  } catch (boost::property_tree::ptree_error &e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  
  std::string result_down = join_vector(vec_down);
  std::string result_up = join_vector(vec_up);
  
  const char* const delim = ", ";
  cout << "Mode: " << mode << "\n";
  if (mode == "ge_results"){
    path filtered_down = dir / "filtered.down.json";
    path filtered_up = dir / "filtered.up.json";
    std::ofstream fout_down(filtered_down.c_str());
    std::ofstream fout_up(filtered_up.c_str());
    cout << "write " << filtered_down << "\n";
    fout_down << "[" << result_down << "]"; //join_vector(vec_down, ",");
    cout << "write " << filtered_up << "\n";
    fout_up << "[" << result_up << "]";
    fout_down.close();
    fout_up.close();
  }
  //  std::ofstream filtered_stats;

  //  filtered_stats.open(filtered_stats_path, std::ios_base::app); // append instead of overwrite
  std::ofstream filtered_stats; //{filtered_stats_path, std::ios_base::app};

  filtered_stats.open(filtered_stats_path.c_str(), std::ios_base::app);
  cout << "write:" << filtered_stats_path.c_str() <<  "\n" ; //result_down.size()
  filtered_stats << run_id + "\t" << vec_up.size() << "\t" << vec_down.size() << "\n"; 
  filtered_stats.close();

}
