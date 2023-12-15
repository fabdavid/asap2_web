#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <boost/algorithm/string.hpp>
#include <boost/filesystem.hpp>
#include <sstream>

/*
#define UPFILE TEXT("filtered_up.json")
#define DOWNFILE TEXT("filtered_down.json")
*/

// TO COMPILE: g++ -o filter_de filter_de.cpp -lboost_system -lboost_filesystem

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
  string logfc_cutoff = argv[3];
  string mode = argv[4];
  string user_id = argv[5];
  string run_id = argv[6];

  //  cout << "PATH: " << argv[0] << "\n";
  //  cout << "FDR: " << argv[1] << "\n";
  //  cout << "LOG_FC: " << argv[2] << "\n";
  
  //  (type=='de_results') ? (@project_dir + 'tmp' + "#{(current_user) ? current_user.id : 0}_de_filtered_stats.json") : (@project_dir + 'tmp' + "#{(current_user) ? current_user.id : "0"}_ge_form_filtered_stats.txt")


  //  getline(cin, input_filepath);

  //  cout <<  input_filepath << "\n";
  
  path project_path (project_filepath);
  path de_path = project_path / "de";
  path input_filepath = de_path / run_id / "output.txt";
  path dir = de_path / run_id; //p.parent_path();
  path tmp_dir =  project_path / "tmp";
  
  path filtered_stats_path;
  if (mode == "de_results"){
    filtered_stats_path = tmp_dir / (user_id + "_de_filtered_stats.txt");
  }else{
    filtered_stats_path = tmp_dir / (user_id + "_ge_form_filtered_stats.txt");
  }


  //  cout << "parent dir: " << dir << "\n";
  
  std::ifstream fin(input_filepath.c_str());
  
  std::string line;
  std::vector <int> vec_down;
  std::vector <int> vec_up;
  
  int i = 0;
  while (getline(fin, line)) {
    // Split line into tab-separated parts
    vector<string> t;
    split(t, line, boost::is_any_of("\t"));
    
    if (t[7] != "NA" && sciToDub(t[7]) <= sciToDub(fdr_cutoff)){
      if (sciToDub(t[5]) >= 0 && sciToDub(t[5]) >= sciToDub(logfc_cutoff)){
	vec_up.push_back(i);
      }else{
	if (sciToDub(t[5]) <= 0 and sciToDub(t[5]) <= -sciToDub(logfc_cutoff)){
	  vec_down.push_back(i);
	} 
      }
    }    
    
    /*    if (sciToDub(t[0])<1){
      cout << "First of " << t.size() << " elements: " << sciToDub(t[0]) << endl;    
      }*/
    i++;
  }
  fin.close();

  std::string result_down = join_vector(vec_down);
  std::string result_up = join_vector(vec_up);
  
  const char* const delim = ", ";
  cout << "Mode: " << mode << "\n";
  if (mode == "de_results"){
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

  }else{
    path filtered_path = tmp_dir / (user_id + "_" + run_id + "_filtered.json");
      //"#{(current_user) ? current_user.id : 1}_#{annot.run_id}_filtered.json
    std::ofstream fout(filtered_path.c_str());
    cout << "write " << filtered_path << "\n";
    fout << "{\"down\" : [" << result_down << "], \"up\" : [" << result_up << "]}";
    fout.close();
  }
  //  std::ofstream filtered_stats;

  //  filtered_stats.open(filtered_stats_path, std::ios_base::app); // append instead of overwrite
  std::ofstream filtered_stats; //{filtered_stats_path, std::ios_base::app};

  filtered_stats.open(filtered_stats_path.c_str(), std::ios_base::app);
  //cout << "down:" << result_down.size()
  filtered_stats << run_id + "\t" << vec_up.size() << "\t" << vec_down.size() << "\n"; 
  filtered_stats.close();

}
