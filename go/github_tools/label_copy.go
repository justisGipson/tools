package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
)

const (
	ghDomain       = "https://api.github.com"
	ghAcceptHeader = "application/vnd.github.symmetra-preview+json"
)

type Label struct {
	Name        string `json:"name"`
	Color       string `json:"color"`
	Description string `json:"description"`
}

func main() {
	ghToken := os.Getenv("GH_TOKEN") // or just hardcode it and remove this line
	if ghToken == "" {
		fmt.Println("GH_TOKEN is not set")
		os.Exit(1)
	}

	srcGhUser := "source_user"
	srcGhRepo := "source_repo"
	tgtGhUser := "target_user"
	tgtGhRepo := "target_repo"

	sourceLabels, err := getSourceLabels(srcGhUser, srcGhRepo, ghToken)
	if err != nil {
		fmt.Printf("Failed to get source labels: %v\n", err)
		os.Exit(1)
	}

	for _, label := range sourceLabels {
		err := createOrUpdateLabel(tgtGhUser, tgtGhRepo, label, ghToken)
		if err != nil {
			fmt.Printf("Failed to create or update label: %v\n", err)
		}
	}
}

func getSourceLabels(user, repo, token string) ([]Label, error) {
	url := fmt.Sprintf("%s/repos/%s/%s/labels?per_page=100", ghDomain, user, repo)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Accept", ghAcceptHeader)
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var labels []Label
	err = json.Unmarshal(body, &labels)
	if err != nil {
		return nil, err
	}

	return labels, nil
}

func createOrUpdateLabel(user, repo string, label Label, token string) error {
	createURL := fmt.Sprintf("%s/repos/%s/%s/labels", ghDomain, user, repo)
	updateURL := fmt.Sprintf("%s/repos/%s/%s/labels/%s", ghDomain, user, repo, label.Name)

	labelJSON, err := json.Marshal(label)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", createURL, nil)
	if err != nil {
		return err
	}

	req.Header.Set("Accept", ghAcceptHeader)
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	labelBase64 := base64.StdEncoding.EncodeToString(labelJSON)
	req.Body = io.NopCloser(base64.NewDecoder(base64.StdEncoding, strings.NewReader(labelBase64)))

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusCreated {
		fmt.Printf("Label created: %s\n", label.Name)
		return nil
	}

	req, err = http.NewRequest("PATCH", updateURL, nil)
	if err != nil {
		return err
	}

	req.Header.Set("Accept", ghAcceptHeader)
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	req.Body = io.NopCloser(base64.NewDecoder(base64.StdEncoding, strings.NewReader(labelBase64)))

	resp, err = client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		fmt.Printf("Label updated: %s\n", label.Name)
	} else {
		fmt.Printf("Failed to update label: %s\n", label.Name)
	}

	return nil
}
